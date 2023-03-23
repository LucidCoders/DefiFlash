// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IFlashProvider.sol";
import "../interfaces/IPancakeRouter01.sol";

contract EqzBorrower is IERC3156FlashBorrower {
    address FLASH_PROVIDER_ADDRESS = 0xEe7e961f77066c5E995615ae7e7E8e4366d9eC5A;
    uint256 MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 loanAmount;
    address payable owner;
    address[] tokenPath;
    address[] routerPath;
    IFlashProvider iProvider;

    event TradeExecuted(uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        iProvider = IFlashProvider(FLASH_PROVIDER_ADDRESS);
    }

    // @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        loanAmount = amount;

        IERC20 loanToken = IERC20(token);
        uint256 allowance = loanToken.allowance(initiator, msg.sender);
        if (allowance <= amount) {
            loanToken.approve(msg.sender, MAX_INT);
        }

        performArbitrage();
        resetValues();

        // Return success to the lender, he will transfer get the funds back if allowance is set accordingly
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function requestArbitrageLoan(
        address[] calldata _tokenPath,
        address[] calldata _routerPath,
        uint256 _amount
    ) public {
        resetValues();
        tokenPath = _tokenPath;
        routerPath = _routerPath;
        iProvider.flashLoan(this, tokenPath[0], _amount, "0x");
    }

    function performArbitrage() private {
        IERC20 loanToken = IERC20(tokenPath[0]);
        IERC20 tradeToken = IERC20(tokenPath[tokenPath.length - 1]);

        approveToken(loanToken, routerPath[0]);
        approveToken(tradeToken, routerPath[1]);
        performSwaps();
    }

    function performSwaps() private {
        IPancakeRouter01 buyOnRouter = IPancakeRouter01(routerPath[0]);
        IPancakeRouter01 sellOnRouter = IPancakeRouter01(routerPath[1]);

        uint256 buyDeadline = block.timestamp + 120;
        uint256[] memory amounts = buyOnRouter.swapExactTokensForTokens(
            loanAmount,
            0,
            tokenPath,
            address(this),
            buyDeadline
        );
        uint256 tradeTokenAmount = amounts[1];
        uint256 sellDeadline = block.timestamp + 120;

        address[] memory invertedPath = invertPath(tokenPath);
        uint256[] memory amounts2 = sellOnRouter.swapExactTokensForTokens(
            tradeTokenAmount,
            0,
            invertedPath,
            address(this),
            sellDeadline
        );
        uint256 loanTokenAmount = amounts2[1];
        emit TradeExecuted(loanTokenAmount);
    }

    function resetValues() private {
        loanAmount = 0;
        delete tokenPath;
        delete routerPath;
    }

    function approveToken(IERC20 _token, address _address) private {
        uint256 allowance = _token.allowance(address(this), _address);
        if (allowance <= 0) {
            _token.approve(_address, MAX_INT);
        }
    }

    function invertPath(
        address[] memory _array
    ) internal pure returns (address[] memory) {
        address[] memory invertedArray = new address[](_array.length);
        for (uint256 i = 0; i < _array.length; i++) {
            invertedArray[i] = _array[_array.length - i - 1];
        }
        return invertedArray;
    }

    function withdrawToken(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    receive() external payable {}
}
