// SPDX-License-Identifier: MIT
// NOTE: this script is ours (MIT). It deploys UNMODIFIED GPL-3.0 Dinari contracts
// (dinaricrypto/sbt-contracts) as a testnet port. See THIRD_PARTY_NOTICES.md.
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DShare} from "../sbt/src/DShare.sol";
import {TransferRestrictor} from "../sbt/src/TransferRestrictor.sol";
import {ITransferRestrictor} from "../sbt/src/ITransferRestrictor.sol";

/// @notice Testnet port of real Dinari contracts: permissive (empty) blacklist restrictor
///         + tNVDA.d DShare behind ERC1967 proxies. Deployer gets admin/minter for testing.
///         Usage: forge script script/PortDShare.s.sol --rpc-url $ARC_TESTNET_RPC --broadcast
contract PortDShare is Script {
    function run() external {
        uint256 key = vm.envUint("DEPLOYER_KEY");
        address admin = vm.addr(key);
        vm.startBroadcast(key);

        TransferRestrictor restrImpl = new TransferRestrictor();
        TransferRestrictor restrictor = TransferRestrictor(
            address(new ERC1967Proxy(address(restrImpl), abi.encodeCall(restrImpl.initialize, (admin, admin))))
        );

        DShare impl = new DShare();
        DShare dshare = DShare(
            address(
                new ERC1967Proxy(
                    address(impl),
                    abi.encodeCall(impl.initialize, (admin, "testNVDA", "tNVDA.d", ITransferRestrictor(address(restrictor))))
                )
            )
        );
        dshare.grantRole(dshare.MINTER_ROLE(), admin);
        dshare.mint(admin, 10_000e18);
        vm.stopBroadcast();

        console2.log("restrictor:", address(restrictor));
        console2.log("dshare:", address(dshare));
        console2.log("balancePerShare:", dshare.balancePerShare());
        console2.log("decimals:", dshare.decimals());
    }
}
