// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
