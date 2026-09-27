// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {StackConfig} from "./StackConfig.sol";
import {IStackVault, IStackPrice, IStackSwap} from "./interfaces/IStackModules.sol";

/// @title StackUp
/// @notice Custodies real spot stock, extends protocol USDC financing, mints one transferable Stack NFT per position.
/// @dev Long-only, one stock per token. Financed opens draw from StackVault and buy more of the same stock.
///      Transfers carry stock + debt unchanged and clear the delegate. Liquidations are full, permissionless, unrewarded.
///
///      Custody modes per asset (chosen at listing, immutable):
///      - RAW: `units` are raw token units (fixed-supply tokens, e.g. test mocks, B20-style where the
///        feed is already total-return adjusted). Behavior is 1 unit = 1 token.
///      - SHARE: `units` are pool shares for rebasing-capable tokens (e.g. Dinari dShares, whose balances
///        change on stock splits). Effective balance = units * custodyBalance / poolShares, so splits
///        (up or down) flow through pro-rata, no funds get stuck, and NAV stays honest.
///      Payouts round DOWN; sub-unit dust remains in custody and slightly benefits remaining holders.
///      Non-stock tokens received by this contract (e.g. USD+ dividend distributions to an unverified
///      holder) never belong to any position and can be swept to treasury via `sweep`.
contract StackUp is ERC721 {
    using SafeERC20 for IERC20;

    struct Listing {
        address stock;
        uint8 stockDec;
        IStackPrice price;
        IStackSwap swap;
        bool openable;
        bool shareMode;
    }

    struct Stack {
        uint256 assetId;
        uint256 units;
        uint256 principal;
        uint256 accrued;
        uint256 updatedAt;
        address delegate;
    }

    struct Health {
        uint256 nav;
        uint256 debt;
        bool unwindable;
    }

    error BadInput();
    error BadLeverage();
    error NoAsset();
    error Closed();
    error NotOwner();
    error NotManager();
    error DebtLeft(uint256 debt);
    error NothingToPay();
    error PoolUnset();
    error NotOpener();
    error NotAdmin();
    error StaleFeed();
    error TooSmall();
    error OverLevered();
    error NotUnwindable();
    error NoteTooLong();
    error ZeroShares();
    error ProtectedToken();

    event StackOpened(uint256 indexed tokenId, address indexed owner, uint256 indexed assetId, uint256 stockAmount);
    event LoanDrawn(uint256 indexed tokenId, uint256 usdc);
    event LoanRepaid(uint256 indexed tokenId, uint256 usdc);
    event Trimmed(uint256 indexed tokenId, uint256 stockSold, uint256 usdcOut);
    event DelegateSet(uint256 indexed tokenId, address indexed oldWho, address indexed newWho);
    event StackClosed(uint256 indexed tokenId, address indexed owner, uint256 stockAmount);
    event StackUnwound(uint256 indexed tokenId, address indexed owner, uint256 stockSold, uint256 usdcOut);
    event ShortfallCovered(uint256 indexed tokenId, uint256 shortfall);
    event VaultLinked(address indexed vault);
    event AssetListed(uint256 indexed assetId, address indexed stock, bool shareMode);
    event AssetGated(uint256 indexed assetId, bool openable);
    event Swept(address indexed token, address indexed to, uint256 amount);

    uint256 public constant MAX_NOTE = 280;
    string public constant CARD_BASE = "https://stackup.fun/api/cards/";

    IERC20 public immutable USDC;
    address public immutable OPENER;
    address public immutable ADMIN;

    IStackVault public vault;

    mapping(uint256 => Stack) private _stacks;
    mapping(uint256 => string) public noteOf;
    mapping(uint256 => Listing) private _listings;
    mapping(address => uint256) public idOf;
    mapping(address => bool) private _usedAdapter;
    mapping(uint256 => uint256) public poolShares;
    uint256[] private _ids;
    uint256 private _nextId;
    uint256 private _nextAsset;

    constructor(address usdc_, address admin_) ERC721("StackUp Stack", "STACK") {
        if (usdc_ == address(0) || admin_ == address(0)) revert BadInput();
        USDC = IERC20(usdc_);
        OPENER = msg.sender;
        ADMIN = admin_;
    }

    function linkVault(address v) external {
        if (msg.sender != OPENER) revert NotOpener();
        if (address(vault) != address(0)) revert PoolUnset();
        if (v == address(0)) revert BadInput();
        IStackVault c = IStackVault(v);
        if (c.USDC() != address(USDC) || c.stackUp() != address(this)) revert BadInput();
        vault = c;
        emit VaultLinked(v);
    }

    function listAsset(
        address stock,
        uint8 stockDec,
        address price,
        address swap,
        bool shareMode
    ) external returns (uint256 assetId) {
        if (msg.sender != ADMIN) revert NotAdmin();
        if (stock == address(0) || price == address(0) || swap == address(0)) revert BadInput();
        if (idOf[stock] != 0 || _usedAdapter[price] || _usedAdapter[swap] || price == swap) revert BadInput();
        IStackPrice p = IStackPrice(price);
        IStackSwap s = IStackSwap(swap);
        if (p.STOCK() != stock || s.STOCK() != stock || s.USDC() != address(USDC)) revert BadInput();
        assetId = ++_nextAsset;
        _listings[assetId] =
            Listing({stock: stock, stockDec: stockDec, price: p, swap: s, openable: true, shareMode: shareMode});
        idOf[stock] = assetId;
        _usedAdapter[price] = true;
        _usedAdapter[swap] = true;
        _ids.push(assetId);
        emit AssetListed(assetId, stock, shareMode);
    }

    function gateAsset(uint256 assetId, bool openable) external {
        if (msg.sender != ADMIN) revert NotAdmin();
        Listing storage l = _getListing(assetId);
        l.openable = openable;
        emit AssetGated(assetId, openable);
    }

    /// @notice Forward stray non-stock tokens (e.g. USD+ dividends paid to this unverified holder)
    ///         to treasury. Listed stocks are protected: custody math owns them.
    function sweep(address token, address to) external {
        if (msg.sender != ADMIN) revert NotAdmin();
        if (to == address(0)) revert BadInput();
        if (idOf[token] != 0) revert ProtectedToken();
        uint256 amt = IERC20(token).balanceOf(address(this));
        if (amt == 0) revert NothingToPay();
        IERC20(token).safeTransfer(to, amt);
        emit Swept(token, to, amt);
    }

    function assetCount() external view returns (uint256) {
        return _ids.length;
    }

    function listing(uint256 assetId) external view returns (Listing memory) {
        return _getListing(assetId);
    }

    /// @notice Effective token balance backing `units` of an asset (rebases included).
    function effectiveStock(uint256 assetId, uint256 units) public view returns (uint256) {
        Listing storage l = _getListing(assetId);
        if (!l.shareMode) return units;
        uint256 pool = poolShares[assetId];
        if (pool == 0) return 0;
        return Math.mulDiv(units, IERC20(l.stock).balanceOf(address(this)), pool, Math.Rounding.Floor);
    }

    /// @notice Effective token balance backing one position.
    function effectiveStockOf(uint256 tokenId) public view returns (uint256) {
        Stack storage st = _stacks[tokenId];
        if (st.assetId == 0) return 0;
        return effectiveStock(st.assetId, st.units);
    }

    /// @notice Deposit stock, optionally stack leverage, mint the portrait NFT.
    /// @dev `stockAmount` is raw tokens in, always. Stored units are raw (RAW mode) or pool shares (SHARE).
    function openStack(
        uint256 assetId,
        uint256 stockAmount,
        uint256 leverageBps,
        uint256 minOut,
        string calldata note
    ) external returns (uint256 tokenId) {
        if (stockAmount == 0) revert BadInput();
        if (!StackConfig.isPreset(leverageBps)) revert BadLeverage();
        if (bytes(note).length > MAX_NOTE) revert NoteTooLong();
        Listing storage l = _getListing(assetId);
        if (!l.openable) revert Closed();

        IERC20 stock = IERC20(l.stock);
        uint256 balBefore = stock.balanceOf(address(this));
        stock.safeTransferFrom(msg.sender, address(this), stockAmount);

        uint256 loan;
        if (leverageBps == StackConfig.SPOT) {
            if (minOut != 0) revert BadInput();
        } else {
            loan = _stacked(l, stockAmount, leverageBps, minOut);
        }

        uint256 inflow = stock.balanceOf(address(this)) - balBefore;
        if (inflow == 0) revert TooSmall();
        uint256 units = _mintUnits(assetId, l, balBefore, inflow);

        tokenId = ++_nextId;
        Stack storage st = _stacks[tokenId];
        st.assetId = assetId;
        st.units = units;
        st.updatedAt = block.timestamp;
        if (bytes(note).length != 0) noteOf[tokenId] = note;

        emit StackOpened(tokenId, msg.sender, assetId, inflow);
        if (loan != 0) {
            st.principal = loan;
            emit LoanDrawn(tokenId, loan);
        }
        _safeMint(msg.sender, tokenId);
    }

    function repay(uint256 tokenId, uint256 amount) external {
        (, Stack storage st) = _manager(tokenId);
        _accrue(st);
        uint256 pay = Math.min(amount, st.principal + st.accrued);
        if (pay == 0) revert NothingToPay();
        _apply(st, pay);
        USDC.safeTransferFrom(msg.sender, address(vault), pay);
        emit LoanRepaid(tokenId, pay);
    }

    /// @notice Sell exact EFFECTIVE stock from this stack and waterfall proceeds into debt. LIVE only.
    function trim(uint256 tokenId, uint256 stockAmount, uint256 minOut) external {
        (address owner, Stack storage st) = _manager(tokenId);
        Listing storage l = _getListing(st.assetId);
        uint256 effective = effectiveStock(st.assetId, st.units);
        if (stockAmount == 0 || stockAmount > effective) revert BadInput();
        _accrue(st);

        if (l.shareMode) {
            uint256 pool = poolShares[st.assetId];
            uint256 burn = Math.mulDiv(
                stockAmount, pool, IERC20(l.stock).balanceOf(address(this)), Math.Rounding.Floor
            );
            if (burn == 0) revert ZeroShares();
            if (burn > st.units) burn = st.units;
            st.units -= burn;
            poolShares[st.assetId] = pool - burn;
        } else {
            st.units -= stockAmount;
        }

        IStackPrice.Quote memory q = _live(l.price);
        uint256 out = _sell(l, stockAmount, minOut, q.price);
        _settle(tokenId, st, owner, out);
        emit Trimmed(tokenId, stockAmount, out);
    }

    function setDelegate(uint256 tokenId, address who) external {
        _owner(tokenId);
        Stack storage st = _stacks[tokenId];
        address old = st.delegate;
        st.delegate = who;
        emit DelegateSet(tokenId, old, who);
    }

    function closeStack(uint256 tokenId) external {
        address owner = _owner(tokenId);
        if (debtOf(tokenId) != 0) revert DebtLeft(debtOf(tokenId));
        Stack storage st = _stacks[tokenId];
        Listing storage l = _getListing(st.assetId);
        uint256 amt = effectiveStock(st.assetId, st.units);
        if (l.shareMode) poolShares[st.assetId] -= st.units;
        delete _stacks[tokenId];
        _burn(tokenId);
        IERC20(l.stock).safeTransfer(owner, amt);
        emit StackClosed(tokenId, owner, amt);
    }

    /// @notice Permissionless full unwind when LIVE and equity/NAV < 30%. No reward. Shortfall hits treasury.
    function liquidate(uint256 tokenId) external {
        address owner = _exists(tokenId);
        Stack storage st = _stacks[tokenId];
        Listing storage l = _getListing(st.assetId);
        _accrue(st);
        IStackPrice.Quote memory q = _live(l.price);
        uint256 d = st.principal + st.accrued;
        uint256 eff = effectiveStock(st.assetId, st.units);
        if (!StackConfig.mustUnwind(l.price.valueUsdc(eff, q.price), d)) revert NotUnwindable();
        if (l.shareMode) poolShares[st.assetId] -= st.units;
        st.units = 0;

        uint256 out = eff == 0 ? 0 : _sell(l, eff, 0, q.price);
        uint256 short = _settle(tokenId, st, owner, out);
        if (short != 0) emit ShortfallCovered(tokenId, short);
        delete _stacks[tokenId];
        _burn(tokenId);
        emit StackUnwound(tokenId, owner, eff, out);
    }

    function debtOf(uint256 tokenId) public view returns (uint256) {
        Stack storage st = _stacks[tokenId];
        return st.principal + st.accrued + _pending(st);
    }

    function stacks(uint256 tokenId) external view returns (Stack memory) {
        return _stacks[tokenId];
    }

    function healthOf(uint256 tokenId) external view returns (Health memory h) {
        _exists(tokenId);
        Stack storage st = _stacks[tokenId];
        Listing storage l = _getListing(st.assetId);
        IStackPrice.Quote memory q = _live(l.price);
        h.nav = l.price.valueUsdc(effectiveStock(st.assetId, st.units), q.price);
        h.debt = st.principal + st.accrued + _pending(st);
        h.unwindable = StackConfig.mustUnwind(h.nav, h.debt);
    }

    function _baseURI() internal pure override returns (string memory) {
        return CARD_BASE;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        from = super._update(to, tokenId, auth);
        if (from != address(0) && to != address(0) && from != to) _stacks[tokenId].delegate = address(0);
    }

    function _mintUnits(
        uint256 assetId,
        Listing storage l,
        uint256 balBefore,
        uint256 inflow
    ) private returns (uint256 units) {
        if (!l.shareMode) return inflow;
        uint256 pool = poolShares[assetId];
        units = (pool == 0 || balBefore == 0)
            ? inflow
            : Math.mulDiv(inflow, pool, balBefore, Math.Rounding.Floor);
        if (units == 0) revert ZeroShares();
        poolShares[assetId] = pool + units;
    }

    function _stacked(
        Listing storage l,
        uint256 deposit,
        uint256 lev,
        uint256 minOut
    ) private returns (uint256 loan) {
        if (address(vault) == address(0)) revert PoolUnset();
        IStackPrice.Quote memory q = _live(l.price);
        uint256 contrib = l.price.valueUsdc(deposit, q.price);
        uint256 ideal = Math.mulDiv(contrib, lev - StackConfig.BPS, StackConfig.BPS);
        loan = Math.mulDiv(ideal, StackConfig.ADVERSE_BPS, StackConfig.BPS);
        if (loan == 0) revert TooSmall();
        vault.draw(loan);
        USDC.forceApprove(address(l.swap), loan);
        uint256 bought = l.swap.buy(loan, minOut, q.price);
        USDC.forceApprove(address(l.swap), 0);
        uint256 nav = l.price.valueUsdc(deposit + bought, q.price);
        if (loan >= nav || nav * StackConfig.BPS > (nav - loan) * lev) revert OverLevered();
    }

    function _getListing(uint256 assetId) private view returns (Listing storage l) {
        l = _listings[assetId];
        if (l.stock == address(0)) revert NoAsset();
    }

    function _exists(uint256 tokenId) private view returns (address owner) {
        owner = _ownerOf(tokenId);
        if (owner == address(0)) revert BadInput();
    }

    function _owner(uint256 tokenId) private view returns (address owner) {
        owner = _exists(tokenId);
        if (msg.sender != owner) revert NotOwner();
    }

    function _manager(uint256 tokenId) private view returns (address owner, Stack storage st) {
        owner = _exists(tokenId);
        st = _stacks[tokenId];
        if (msg.sender != owner && msg.sender != st.delegate) revert NotManager();
    }

    function _live(IStackPrice p) private view returns (IStackPrice.Quote memory q) {
        q = p.latest();
        if (q.state != IStackPrice.FeedState.LIVE) revert StaleFeed();
    }

    function _pending(Stack storage st) private view returns (uint256) {
        if (st.principal == 0 || block.timestamp <= st.updatedAt) return 0;
        return Math.mulDiv(st.principal, StackConfig.BORROW_APR_BPS * (block.timestamp - st.updatedAt), StackConfig.BPS * StackConfig.YEAR);
    }

    function _accrue(Stack storage st) private {
        uint256 p = _pending(st);
        if (p != 0) st.accrued += p;
        st.updatedAt = block.timestamp;
    }

    function _apply(Stack storage st, uint256 pay) private {
        uint256 i = Math.min(pay, st.accrued);
        st.accrued -= i;
        st.principal -= pay - i;
    }

    function _sell(Listing storage l, uint256 amt, uint256 minOut, uint256 px) private returns (uint256 out) {
        IERC20(l.stock).forceApprove(address(l.swap), amt);
        out = l.swap.sell(amt, minOut, px);
        IERC20(l.stock).forceApprove(address(l.swap), 0);
    }

    function _settle(uint256 tokenId, Stack storage st, address owner, uint256 out) private returns (uint256 short) {
        uint256 d = st.principal + st.accrued;
        uint256 pay = Math.min(out, d);
        if (pay != 0) {
            _apply(st, pay);
            USDC.safeTransfer(address(vault), pay);
            emit LoanRepaid(tokenId, pay);
        }
        if (out > pay) USDC.safeTransfer(owner, out - pay);
        short = d - pay;
    }
}
