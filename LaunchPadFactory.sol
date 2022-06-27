// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILaunchPad.sol";
import "./LaunchPad.sol";

contract LaunchPadFactory is Ownable{

    mapping(address => mapping(address => address)) public _launchPadPair;
    address[] public _launchPadArray;
 
    event createEvent(address fundToken_,address idoToken_,address pair_,uint256 arraryLengh) ;
    
    function createLaunchPadContract(ILaunchPad.LaunchPadInfo memory launchPadInfo_,address addr_) 
        external 
        virtual  
        onlyOwner
        returns(address pair)
    {
        require(launchPadInfo_.idoToken != launchPadInfo_.fundToken,
            "address has been identical"
        );
        require(_launchPadPair[launchPadInfo_.idoToken][launchPadInfo_.fundToken] == address(0),
            "the pair has been exists"
        );
        bytes memory bytecode = type(LaunchPad).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(launchPadInfo_.idoToken, launchPadInfo_.fundToken, address(this)));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ILaunchPad(pair).setLaunchPadInfo(launchPadInfo_,addr_);
        _launchPadArray.push(pair);
        _launchPadPair[launchPadInfo_.idoToken][launchPadInfo_.fundToken] = pair;
        emit createEvent(launchPadInfo_.fundToken,launchPadInfo_.idoToken,pair,_launchPadArray.length);
        return pair;
    }

    function getLaunchPadArrayLength() external view returns(uint256){
        return _launchPadArray.length;
    }

    function getLaunchPadPairAddress(address idoToken,address fundToken) external view returns(address){
        require(fundToken != address(0),"address cannot be address(0)");
        require(idoToken != fundToken,"address cannot be equal");
        return _launchPadPair[idoToken][fundToken];
    }

    function setMerkleRoot(address pair, bytes32 _root) external onlyOwner {
        ILaunchPad(pair).setRoot(_root);
    }

    function withDrawToAccount(address pair) external onlyOwner {
        ILaunchPad(pair).withdrawToAccount();
    }

    function setLaunchFinished(address pair,bool finished_) external onlyOwner{
        ILaunchPad(pair).setFinished(finished_);
    }
}