import { parseAbi } from "viem";

export const stackUpAbi = parseAbi([
  "function openStack(uint256 assetId, uint256 stockAmount, uint256 leverageBps, uint256 minOut, string note) returns (uint256)",
  "function repay(uint256 tokenId, uint256 amount)",
  "function trim(uint256 tokenId, uint256 stockAmount, uint256 minOut)",
  "function setDelegate(uint256 tokenId, address who)",
  "function closeStack(uint256 tokenId)",
  "function liquidate(uint256 tokenId)",
  "function debtOf(uint256 tokenId) view returns (uint256)",
  "function stacks(uint256 tokenId) view returns (uint256 assetId, uint256 units, uint256 principal, uint256 accrued, uint256 updatedAt, address delegate)",
  "function effectiveStockOf(uint256 tokenId) view returns (uint256)",
  "function healthOf(uint256 tokenId) view returns (uint256 nav, uint256 debt, bool unwindable)",
  "function listing(uint256 assetId) view returns (address stock, uint8 stockDec, address price, address swap, bool openable, bool shareMode)",
  "function assetCount() view returns (uint256)",
  "function noteOf(uint256 tokenId) view returns (string)",
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function balanceOf(address owner) view returns (uint256)",
  "function poolShares(uint256 assetId) view returns (uint256)",
  "function vault() view returns (address)",
  "function listing(uint256 assetId) view returns (address stock, uint8 stockDec, address price, address swap, bool openable, bool shareMode)",
  "event StackOpened(uint256 indexed tokenId, address indexed owner, uint256 indexed assetId, uint256 stockAmount)",
  "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)",
]);

export const erc20Abi = parseAbi([
  "function approve(address spender, uint256 amount) returns (bool)",
  "function allowance(address owner, address spender) view returns (uint256)",
  "function balanceOf(address owner) view returns (uint256)",
  "function decimals() view returns (uint8)",
]);

export const stackVaultAbi = parseAbi([
  "function USDC() view returns (address)",
  "function available() view returns (uint256)",
]);

export const stackPriceAbi = parseAbi([
  "function latest() view returns (uint8 state, uint256 price, uint256 updatedAt)",
  "function valueUsdc(uint256 stockAmount, uint256 price) view returns (uint256)",
]);
