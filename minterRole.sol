pragma solidity ^0.5.5;
import "./roles.sol";
import "./context.sol";
// import "./interface.sol";
import "./abstract.sol";



contract MinterRole is Context{

    using Minters for Minters.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event OwnershipTransfer(address indexed account);

    Minters.Role private _admins;
    address private ownerAddr;
    bool public currentState;


    constructor () internal {
        _addMinter(_msgSender());
        _changeOwner(_msgSender());
        currentState = true;

    }

    modifier onlyOwner() {
        require(_msgSender() == Owner(),"MinterRole: caller is not owner");
        _;
      }

    modifier onlyMinter() {
        require(isMinter(_msgSender()) || _msgSender() == Owner(),"MinterRole: caller does not have the Minter role");
        _;
    }
    modifier isNotPaused() {
        require(currentState,"ContractMinter : paused contract for action");
        _;
    }

    function changeState(bool _state) public onlyMinter returns(bool){
        require(_state != currentState,"ContractMinter : same state");
        currentState = _state;
        return _state;
    }

    function Owner() public view returns (address) {
        return ownerAddr;
    }

    function changeOwner(address account) external onlyOwner {
      _changeOwner(account);
    }

    function _changeOwner(address account)internal{
      require(account != address(0) && account != ownerAddr ,"MinterRole: Address is Owner or zero address");
       ownerAddr = account;
       emit OwnershipTransfer(account);
    }

    function isMinter(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addMinter(address account) public onlyMinter {

        _addMinter(account);
    }
    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public{
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _admins.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _admins.remove(account);
        emit MinterRemoved(account);
    }
}


contract BlockRole is MinterRole{

  using blocks for blocks.Role;

  event BlockAdded(address indexed account);
  event BlockRemoved(address indexed account);

  blocks.Role private _blockedUser;


  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

    modifier isNotBlackListed(address account){
       require(!getBlackListStatus(account),"BlockRole : Address restricted");
        _;
    }

    function addBlackList(address account) public onlyMinter {
      _addBlackList(account);
    }

    function removeBlackList(address account) public onlyMinter {
      _removeBlackList(account);
    }

    function getBlackListStatus(address account) public view returns (bool) {
      return _blockedUser.has(account);
    }

    function _addBlackList(address account) internal {
      _blockedUser.add(account);
      emit BlockAdded(account);
    }

    function _removeBlackList(address account) internal {
      _blockedUser.remove(account);
      emit BlockRemoved(account);

    }

}

contract FundController is Context,MinterRole{

constructor() internal {}


    /*
    * @title claimTRX
    * @dev it can let admin withdraw trx from contract
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function claimTRX(address payable to, uint256 value)
    external
    onlyMinter
    returns (bool)
    {
      require(address(this).balance >= value, "FundController: insufficient balance");

      (bool success, ) = to.call.value(value)("");
      require(success, "FundController: unable to send value, accepter may have reverted");
      return true;
    }
    /*
    * @title claimTRC10
    * @dev it can let admin withdraw any trc10 from contract
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @param token The tokenId of token to be transferred.

    */
     function claimTRC10(address payable to, uint256 value, uint256 token)
     external
     onlyMinter
     returns (bool)
    {
      require(value <=  address(this).tokenBalance(token), "FundController: Not enought Token Available");
      to.transferToken(value, token);
      return true;
    }
    /*
    * @title claimTRC20
    * @dev it can let admin withdraw any trc20 from contract
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @param token The contract address of token to be transferred.

    */
    function claimTRC20(address to, uint256 value, address token)
    external
    onlyMinter
    returns (bool)
    {
      (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
      bool result = success && (data.length == 0 || abi.decode(data, (bool)));
      require(result, "FundController: unable to transfer value, recipient or token may have reverted");
      return true;
    }
  /*
  * @title claimTRC721
  * @dev it can let admin withdraw any trc721 from contract
  * @param to The address to transfer to.
  * @param tokenId of token to be transferred.
  * @param token The contract address of token to be transferred.
  */
  function claimTRC721(address payable to,uint256 tokenId , address token)
  external
  onlyMinter
  returns (bool)
  {
      ITRC721(token).safeTransferFrom(address(this),to,tokenId);
      return true;
  }
    //Fallback
    function () external payable { }


    function kill() public onlyOwner {
      selfdestruct(_msgSender());
    }
//
}
contract MinterControl is MinterRole,FundController{
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.

  constructor () internal { }

}
