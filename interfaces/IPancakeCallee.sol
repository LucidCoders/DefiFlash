// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPancakeCallee {
    // BakerySwap does not implement Flash Swaps
    // SafeMoonSwap code not verified

    // Called by PancakeSwap, ApeSwap
    function pancakeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function BiswapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function BabyDogeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function babyCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function fstswapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function nomiswapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
