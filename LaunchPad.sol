// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILaunchPad.sol";


contract LaunchPad is Ownable, ILaunchPad {
    
    IERC20 _fundToken;
    IERC20 _idoToken;
    bool public _finished = false;
    bool public _successed = false;
    bool public _paramset =false;
    uint256 constant  COEFFICENT = 1000;
    uint256 public _length=0;

    bytes32 public root;
    address public _fundOwner;

    LaunchPadInfo public _launchPadInfo;

    mapping(address => uint256) public _balance;
    mapping(address => bool) public _isAddress;

    modifier Addressable(address addr){
        require(addr != address(0), "address cannot be address(0)");
        _;
    }   

    modifier SafeAddress(bytes32[] memory proof){
        require(accountIsValid(proof, keccak256(abi.encodePacked(msg.sender))), 
            "Not a part of Allowlist"
        );
        _;
    }

    function setLaunchPadInfo(LaunchPadInfo memory info,address addr_) external virtual override onlyOwner returns(bool){
        require(info.fundToken != address(0),"myToken address cannot be address(0)");
        require(
            info.startTime >= block.timestamp && info.endTime >info.startTime,
            "launchpad time error"
        );
        require(info.hardTop >= info.softTop ,"launchpad hardtop cannot less than softtop"); 
        require(info.maxAmout >= info.minAmout ,"launchpad max cannot less than min");
        require(info.preSale >= (info.hardTop*info.ratio/COEFFICENT),
            "Insufficient pre-sale quantity"
        );
        _launchPadInfo = info;

        _fundToken = IERC20(_launchPadInfo.fundToken);

        if(info.idoToken != address(0)){
            _idoToken = IERC20(_launchPadInfo.idoToken);
        }

        emit setLaunchPadInfoEvent(_launchPadInfo);

        _fundOwner = addr_;
        _paramset = true;       
        return true;
    }

    function doTransfer(uint256 value,bytes32[] memory proof) 
        external 
        payable
        virtual
        override
        SafeAddress(proof)
    {
        require(bytes32(0) != root,"IDO is public sale");
        onTransfer(value);
    }

    function doTransfer(uint256 value) external payable virtual override
    {      
        require(bytes32(0) == root,"IDO is not public sale");
        onTransfer(value);
    }

    function withdrawToCustomer() 
        external 
        virtual
        override  
    {
        require(checkAddress(msg.sender),"The account has not token");
        require(finished(0),"the launchpad is not over");

        uint256 balance = _balance[msg.sender];
        if(_successed){       
            _fundToken.transfer(msg.sender,balance*_launchPadInfo.ratio/COEFFICENT);
            emit withdrawEvent(_fundToken,msg.sender,balance*_launchPadInfo.ratio/COEFFICENT);
        }else {
            if(_launchPadInfo.idoToken != address(0)){
                _idoToken.transfer(msg.sender,balance);
            }else {
                payable(msg.sender).transfer(balance);
            }           
            emit withdrawEvent(_idoToken,msg.sender,balance);
       }
       _balance[msg.sender] = 0;
    }

    function withdrawToAccount() external virtual override onlyOwner returns(uint256){
        require(finished(0),"the launchpad is not over");
        uint256 balance = getBalanceOf();
        if(_successed){
            if(_launchPadInfo.idoToken != address(0)){
                _idoToken.transfer(_fundOwner,balance);
            }else{
                payable(_fundOwner).transfer(balance);
            }
            return balance;
        }
        return 0;
    }   

    function getBalanceOf() public view virtual override returns(uint256){
        uint256 balance;
        if(_launchPadInfo.idoToken != address(0)){
            balance= _idoToken.balanceOf(address(this));
        }else {
            balance= address(this).balance;
        }
        return balance;
    }

    function getLaunchPadInfo() public view virtual override returns(LaunchPadInfo memory ){
        return _launchPadInfo;
    }

    function setFinished( bool finished_) public virtual override onlyOwner  {
        _finished = finished_;
    }

    function finished(uint256 value) public view virtual override returns(bool){
        uint256 balance = getBalanceOf();
        if(_launchPadInfo.idoToken == address(0)){
            balance = balance - value;
        }
        return _finished||
               (block.timestamp > _launchPadInfo.endTime)||
               (_launchPadInfo.hardTop - balance < _launchPadInfo.minAmout);
    }

    function checkAddress(address addr) public view virtual override Addressable(addr) returns(bool){
        return _isAddress[addr];
    }

    function accountIsValid(bytes32[] memory proof, bytes32 leaf) public view virtual override returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setRoot(bytes32 root_) public virtual override onlyOwner {
        root = root_;
    }

    function getAddressCount() public view virtual override returns(uint256){
        return _length;
    }
    function getFundTokenAmount() public view virtual override returns(uint256){
        return _fundToken.balanceOf(address(this));
    }

    function onTransfer(uint256 value) private {
        require(msg.sender != address(0),"msg.sender address cannot be address(0)");
        require(_paramset,"Please set parameters first");
		if(_balance[msg.sender] < _launchPadInfo.minAmout){
		    require(value >= _launchPadInfo.minAmout,"value is smaller than minAmount.");
		}
        require(_balance[msg.sender] + value <= _launchPadInfo.maxAmout,
                "quantity out of range."); 
        require(block.timestamp > _launchPadInfo.startTime, "activity not started");

        uint256 balance = getBalanceOf();         
        if(_launchPadInfo.idoToken != address(0)){
            require(value <= (_launchPadInfo.hardTop - balance),
                "value cannot be more than remaining quantity");
            if(!_successed){
                if((balance + value) >= _launchPadInfo.softTop){
                    _successed = true;
                }
            }
            require(!finished(0) , "IDO has already over.");
            _idoToken.transferFrom(msg.sender,address(this),value);
        }else {
            require(0 <= (_launchPadInfo.hardTop - balance),
                "msg.value cannot be more than remaining quantity");
            if(!_successed){
                if(balance >= _launchPadInfo.softTop){
                    _successed = true;
                }
            }
            require(msg.value == value,"The entered quantity is inconsistent with the quantity carried by MSG");
            require(!finished(value) , "IDO has already over.");
        }
           
        if(!checkAddress(msg.sender)){
            _length = _length + 1;
            _isAddress[msg.sender] = true;
        }
         _balance[msg.sender] += value;

        emit joinLaunchPad(msg.sender,value);
    }
}
