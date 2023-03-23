// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IPancakeCallee.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter01.sol";

contract CircularSwapsNoApprovals is IPancakeCallee {
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    address payable owner;

    struct SwapInfo {
        uint256 step;
        address[] pairPath;
        address[] tokenPath;
        address[] routerPath;
        uint256[] whichTokenPath;
        uint256[] amountPath;
    }

    /* ###################### Constructors ###################### */

    constructor() {
        owner = payable(msg.sender);
    }

    /* ###################### Class Functions ###################### */

    function circularFlashSwaps(
        address[] calldata _pairPath,
        address[] calldata _tokenPath,
        address[] calldata _routerPath,
        uint256[] calldata _whichTokenPath,
        uint256 _amount
    ) public {
        uint256 step = 0;
        uint256 amount0Out = _whichTokenPath[step] == 0 ? _amount : 0;
        uint256 amount1Out = _whichTokenPath[step] == 1 ? _amount : 0;

        uint256[] memory amountPath;

        SwapInfo memory swapInfo;
        swapInfo.step = step;
        swapInfo.pairPath = _pairPath;
        swapInfo.tokenPath = _tokenPath;
        swapInfo.routerPath = _routerPath;
        swapInfo.whichTokenPath = _whichTokenPath;
        swapInfo.amountPath = amountPath;
        bytes memory data = abi.encode(swapInfo);

        IPancakePair(_pairPath[step]).swap(
            amount0Out,
            amount1Out,
            address(this),
            data
        );
    }

    /* ###################### Callee Implementations ###################### */

    function callee(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) private {
        SwapInfo memory swapInfo = abi.decode(_data, (SwapInfo));
        require(
            msg.sender == swapInfo.pairPath[swapInfo.step],
            "pancakeCall: NOT_PAIR"
        );
        require(_sender == address(this), "pancakeCall: NOT_SENDER");

        uint256 amount = _amount0 > 0 ? _amount0 : _amount1;
        require(amount > 0, "pancakeCall: ZERO_AMOUNT");

        address routerAddress = swapInfo.routerPath[swapInfo.step];
        IPancakeRouter01 router = IPancakeRouter01(routerAddress);

        address[] memory path = new address[](2);
        if (swapInfo.step < swapInfo.pairPath.length - 1) {
            path[0] = swapInfo.tokenPath[swapInfo.step + 1];
            path[1] = swapInfo.tokenPath[swapInfo.step];
        } else {
            path[0] = swapInfo.tokenPath[0];
            path[1] = swapInfo.tokenPath[swapInfo.step];
        }

        uint256[] memory amountsIn = router.getAmountsIn(amount, path);
        uint256 nextAmount = amountsIn[0];
        uint256[] memory amountPath = new uint256[](
            swapInfo.amountPath.length + 1
        );

        for (uint256 index = 0; index < swapInfo.amountPath.length; index++) {
            amountPath[index] = swapInfo.amountPath[index];
        }
        amountPath[amountPath.length - 1] = nextAmount;
        swapInfo.amountPath = amountPath;

        if (swapInfo.step < swapInfo.pairPath.length - 1) {
            nextSwap(swapInfo, nextAmount);
        } else {
            payback(swapInfo);
        }
    }

    function nextSwap(SwapInfo memory swapInfo, uint256 nextAmount) private {
        uint256 nextStep = swapInfo.step + 1;
        uint256 amount0Out = swapInfo.whichTokenPath[nextStep] == 0
            ? nextAmount
            : 0;
        uint256 amount1Out = swapInfo.whichTokenPath[nextStep] == 1
            ? nextAmount
            : 0;

        swapInfo.step = nextStep;
        bytes memory data = abi.encode(swapInfo);

        IPancakePair(swapInfo.pairPath[nextStep]).swap(
            amount0Out,
            amount1Out,
            address(this),
            data
        );
    }

    function payback(SwapInfo memory swapInfo) private {
        address[] memory paybackTokenArray = moveFirstToEnd(swapInfo.tokenPath);
        for (uint256 index = 0; index < swapInfo.amountPath.length; index++) {
            uint256 paybackAmount = swapInfo.amountPath[index];
            IERC20 paybackToken = IERC20(paybackTokenArray[index]);
            paybackToken.transfer(swapInfo.pairPath[index], paybackAmount);
        }
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        callee(_sender, _amount0, _amount1, _data);
    }

    function BiswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        callee(_sender, _amount0, _amount1, _data);
    }

    function BabyDogeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        callee(_sender, _amount0, _amount1, _data);
    }

    function fstswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        callee(_sender, _amount0, _amount1, _data);
    }

    function babyCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        callee(_sender, _amount0, _amount1, _data);
    }

    function nomiswapCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external {
        callee(_sender, _amount0, _amount1, _data);
    }

    /* ###################### Util Functions ###################### */

    function moveFirstToEnd(address[] memory _array)
        private
        pure
        returns (address[] memory)
    {
        address firstElement = _array[0];
        for (uint256 i = 1; i < _array.length; i++) {
            _array[i - 1] = _array[i];
        }
        _array[_array.length - 1] = firstElement;
        return _array;
    }

    /* ###################### Base Functions ###################### */

    function withdrawToken(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawToken(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, _amount);
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
