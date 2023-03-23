# DefiFlash
Smart contracts to perform Flash Loans and Flash Swaps - Targeted for Binance Smartchain

## CircularSwapsNoApprovals.sol
Performs multi pair/cross DEX flash swaps(UniswapV2) in a circular fashion to avoid token approvals.

### EqzBorrower.sol
Implements Equalizer's IERC3156FlashBorrower flash loan protocol and then performs a simple token swap (UniswapV2)
