// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILaunchPad {
    struct LaunchPadInfo {
        address  fundToken;
        address  idoToken;
        uint256  preSale;
        uint256  startTime;
        uint256  endTime;
        uint256  softTop;
        uint256  hardTop;
        uint256  minAmout;
        uint256  maxAmout;
        uint256  ratio;
    }

    event setLaunchPadInfoEvent(LaunchPadInfo info);
    event joinLaunchPad(address sender,uint256 amount);
    event withdrawEvent(IERC20 token,address sender,uint256 amount);

    function setLaunchPadInfo(LaunchPadInfo memory info,address addr_) external returns(bool);
    function withdrawToCustomer() external;
    function doTransfer(uint256 value,bytes32[] memory proof) external payable;
    function doTransfer(uint256 value) external payable;
    function withdrawToAccount() external returns(uint256);
    function getBalanceOf() external view returns(uint256);
    function getLaunchPadInfo() external view returns(LaunchPadInfo memory );
    function getAddressCount() external view returns(uint256);  
    function finished(uint256 value)external view returns(bool);
    function setFinished( bool finished_) external;
    function checkAddress(address addr) external view returns(bool);
    function accountIsValid(bytes32[] memory proof, bytes32 leaf) external view returns (bool);
    function getFundTokenAmount() external view returns(uint256);
    function setRoot(bytes32 root_) external ;  
}
