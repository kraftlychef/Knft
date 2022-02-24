pragma solidity ^0.5.5;
import "./minterRole.sol";
import "./abstract.sol";
import "./library.sol";
import "./safeMath.sol";



/**
 * @dev Implementation of the {ITRC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract TRC165 is ITRC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for TRC165 itself here
        _registerInterface(_INTERFACE_ID_TRC165);
    }

    /**
     * @dev See {ITRC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual TRC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {ITRC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the TRC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "TRC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
contract IKtyNft is  Context,TRC165,IKraftNft,BlockRole{

  using Strings for uint256;


  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;



  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _TRC721_RECEIVED = 0x5175f878;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping (address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  EnumerableMap.UintToAddressMap private _tokenOwners;

  // Mapping from token ID to approved address
  mapping (uint256 => address) private _tokenApprovals;


  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Base URI
  string private _baseURI;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;



  /*
   *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
   *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
   *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
   *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
   *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
   *
   *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
   *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
   */
  bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *
   *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
   */
  bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;

  /*
   *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
   *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
   *
   *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
   */
  bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor (string memory name, string memory symbol) public {
      _name = name;
      _symbol = symbol;

      // register the supported interfaces to conform to TRC721 via TRC165
      _registerInterface(_INTERFACE_ID_TRC721);
      _registerInterface(_INTERFACE_ID_TRC721_METADATA);
      _registerInterface(_INTERFACE_ID_TRC721_ENUMERABLE);
  }

  /**
   * @dev Gets the token name.
   * @return string representing the token name
   */
  function name() external view returns (string memory) {
      return _name;
  }

  /**
   * @dev Gets the token symbol.
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory) {
      return _symbol;
  }

  /**
   * @dev Returns the URI for a given token ID. May return an empty string.
   *
   * If the token's URI is non-empty and a base URI was set (via
   * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
   *
   * Reverts if the token ID does not exist.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
      require(_exists(tokenId), "IKtyNft: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];

      // Even if there is a base URI, it is only appended to non-empty token-specific URIs
      if (bytes(_tokenURI).length == 0) {
          _tokenURI = tokenId.toString();
      }
      // abi.encodePacked is being used to concatenate strings
      return string(abi.encodePacked(_baseURI, _tokenURI));
  }

  /**
   * @dev Internal function to set the token URI for a given token.
   *
   * Reverts if the token ID does not exist.
   *
   * TIP: if all token IDs share a prefix (e.g. if your URIs look like
   * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
   * it and save gas.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
      require(_exists(tokenId), "TRC721Metadata: URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI}.
   *
   * _Available since v2.5.0._
   */
  function _setBaseURI(string memory baseURI) internal {
      _baseURI = baseURI;
  }

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a preffix in {tokenURI} to each token's URI, when
  * they are non-empty.
  *
  * _Available since v2.5.0._
  */
  function baseURI() external view returns (string memory) {
      return _baseURI;
  }
  /**
   * @dev Gets the balance of the specified address.
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address owner) public view returns (uint256) {
      require(owner != address(0), "IKtyNft: balance query for the zero address");

      return _holderTokens[owner].length();
  }

  /**
   * @dev Gets the owner of the specified token ID.
   * @param tokenId uint256 ID of the token to query the owner of
   * @return address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 tokenId) public view returns (address) {
    return _tokenOwners.get(tokenId, "IKtyNft: owner query for nonexistent token");

  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner.
   * @param owner address owning the tokens list to be accessed
   * @param index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < _holderTokens[owner].length(), "IKtyNft: owner index out of bounds");
      return _holderTokens[owner].at(index);
  }
  /**
   * @dev Gets all the tokens ID list of the requested owner.
   * @param owner address owning the tokens list to be accessed
   * @return uint256 array list owned by the requested address
   */
  function tokensOfOwner(address owner) public view returns (uint256 [] memory) {
      return _holderTokens[owner].all();
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract.
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
      // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
      return _tokenOwners.length();
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens.
   * @param index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "IKtyNft: global index out of bounds");
      (uint256 tokenId, ) = _tokenOwners.at(index);
      return tokenId;
  }


  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(_msgSender())

  {
      address owner = ownerOf(tokenId);
      require(to != owner, "IKtyNft: approval to current owner");

      require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
          "IKtyNft: approve caller is not owner nor approved for all"
      );

      _tokenApprovals[tokenId] = to;
      emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 tokenId) public view returns (address) {

      require(_exists(tokenId), "IKtyNft: approved query for nonexistent token");

      return _tokenApprovals[tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf.
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
  function setApprovalForAll(address to, bool approved)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(_msgSender())
  {
      require(to != _msgSender(), "IKtyNft: approve to caller");

      _operatorApprovals[_msgSender()][to] = approved;
      emit ApprovalForAll(_msgSender(), to, approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner.
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address owner, address operator) public view returns (bool) {
      return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address.
   * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   * Requires the msg.sender to be the owner, approved, or operator.
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function transferFrom(address from, address to, uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(from)
  {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "IKtyNft: transfer caller is not owner nor approved");

      _transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement {ITRC721Receiver-onTRC721Received},
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   */
  function safeTransferFrom(address from, address to, uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(from)
  {
      safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement {ITRC721Receiver-onTRC721Received},
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the _msgSender() to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
  public
  isNotPaused
  isNotBlackListed(to)
  isNotBlackListed(from)
   {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "IKtyNft: transfer caller is not owner nor approved");
      _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg.sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
      _transfer(from, to, tokenId);
      require(_checkOnTRC721Received(from, to, tokenId, _data), "IKtyNft: transfer to non TRC721Receiver implementer");
  }

  /**
   * @dev Returns whether the specified token exists.
   * @param tokenId uint256 ID of the token to query the existence of
   * @return bool whether the token exists
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
      return _tokenOwners.contains(tokenId);
  }


  /**
   * @dev Returns whether the given spender can transfer a given token ID.
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
      require(_exists(tokenId), "IKtyNft: operator query for nonexistent token");
      address owner = ownerOf(tokenId);
      return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _safeMint(address to, uint256 tokenId) internal {
      _safeMint(to, tokenId, "");
  }

  /**
   * @dev Internal function to safely mint a new token.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   * @param _data bytes data to send along with a safe transfer check
   */
  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
      _mint(to, tokenId);
      require(_checkOnTRC721Received(address(0), to, tokenId, _data), "IKtyNft: minting to non TRC721Receiver implementer");
  }

  /**
   * @dev Internal function to mint a new token.
   * Reverts if the given token ID already exists.
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted
   */
  function _mint(address to, uint256 tokenId) internal {
      require(to != address(0), "IKtyNft: mint to the zero address");
      require(!_exists(tokenId), "IKtyNft: token already minted");

      _holderTokens[to].add(tokenId);

      _tokenOwners.set(tokenId, to);

      emit Transfer(address(0), to, tokenId);
  }
  /**
   * @dev Function to burn a specific token.
   * @param tokenId The token id to burned.
   * Reverts if the token does not exist.
   * return true if burned
   */
  function burn(uint256 tokenId)
  public
  isNotPaused
  isNotBlackListed(_msgSender())
  returns (bool) {
      require(_exists(tokenId), "IKtyNft: operator query for nonexistent token");
      _burn(tokenId,_msgSender());
      return true;
  }

  /**
   * @dev Internal function to burn a specific token.
   * Reverts if the token does not exist.
   * Deprecated, use {_burn} instead.
   * @param owner owner of the token to burn
   * @param tokenId uint256 ID of the token being burned
   */
  function _burn(uint256 tokenId,address owner) internal {
      require(ownerOf(tokenId) == owner, "IKtyNft: burn of token that is not own");

      _clearApproval(tokenId);


      _holderTokens[owner].remove(tokenId);

      _tokenOwners.remove(tokenId);

      emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) internal {
      require(ownerOf(tokenId) == from, "IKtyNft: transfer of token that is not own");
      require(to != address(0), "IKtyNft: transfer to the zero address");

      // Clear approvals from the previous owner
      _clearApproval(tokenId);


      _holderTokens[from].remove(tokenId);
      _holderTokens[to].add(tokenId);

      _tokenOwners.set(tokenId, to);

      emit Transfer(from, to, tokenId);
  }


  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnTRC721Received(address from, address to, uint256 tokenId, bytes memory _data)
      internal returns (bool)
  {
      if (!to.isContract) {
          return true;
      }
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
          ITRC721Receiver(to).onTRC721Received.selector,
          _msgSender(),
          from,
          tokenId,
          _data
      ));
      if (!success) {
          if (returndata.length > 0) {
              // solhint-disable-next-line no-inline-assembly
              assembly {
                  let returndata_size := mload(returndata)
                  revert(add(32, returndata), returndata_size)
              }
          } else {
              revert("TRC721: transfer to non TRC721Receiver implementer");
          }
      } else {
          bytes4 retval = abi.decode(returndata, (bytes4));
          return (retval == _TRC721_RECEIVED);
      }
  }

  function _clearApproval(uint256 tokenId) private {
      if (_tokenApprovals[tokenId] != address(0)) {
          _tokenApprovals[tokenId] = address(0);
          emit Approval(ownerOf(tokenId), address(0), tokenId);

      }
  }

}




contract KraftNft is Context, MinterControl,IKtyNft{
  using SafeMath for uint256;
  // total number of nft minted in series
  uint256 private serialCount;


  constructor() public IKtyNft("KRAFT NFT", "KNFT") {
    serialCount = 1;
  }
  /**
   * @dev  Function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI}.
   * return true, if baseURI set successfully
   *
   * _Available since v2.5.0._
   */
  function setBaseURI(string memory baseURI) public onlyMinter returns(bool){
      _setBaseURI(baseURI);
      return true;
  }

  /*
  *@dev function returns successfully minted nft by serial number
  */
  function getSerialMintedCount() public view returns (uint256){
    return serialCount;
  }
  /*
  * @dev function to update serial count of nft in case minted by other function mistakely
  */
  function updateSerialCount(uint256 value) public onlyMinter{
    require(value > 0,"MintNft: null Value provided");
     serialCount = value;
  }
  /**
   * @dev Internal function to safely mint a new token of serialised tokenId.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   */
  function serialMint(address to) public
  onlyMinter
  isNotPaused
  returns (uint256) {
      _safeMint(to, serialCount);
      serialCount += 1;
      return serialCount -1;
  }
  /**
   * @dev Internal function to safely mint a new token of serialised tokenId.
   * Reverts if the given token ID already exists.
   * If the target address is a contract, it must implement `onTRC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * @param to The address that will own the minted token
   * @param tokenURI The token URI of the minted token.

   */
  function serialMint(address to, string memory tokenURI) public
  onlyMinter
  isNotPaused
  returns (uint256) {
      _safeMint(to, serialCount);
      _setTokenURI(serialCount, tokenURI);
      serialCount += 1;
      return serialCount-1;
  }
  /**
   * @dev Function to mint tokens.
   * @param to The address that will receive the minted tokens.
   * @param tokenId The token id to mint.
   * @param tokenURI The token URI of the minted token.
   * @return A boolean that indicates if the operation was successful.
   */
  function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _mint(to, tokenId);
      _setTokenURI(tokenId, tokenURI);
      return true;
  }
  /**
   * @dev Function to mint tokens.
   * @param to The address that will receive the minted token.
   * @param tokenId The token id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address to, uint256 tokenId) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _mint(to, tokenId);
      return true;
  }
  /**
   * @dev Function to safely mint tokens.
   * @param to The address that will receive the minted token.
   * @param tokenId The token id to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function safeMint(address to, uint256 tokenId) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _safeMint(to, tokenId);
      return true;
  }

  /**
   * @dev Function to safely mint tokens.
   * @param to The address that will receive the minted token.
   * @param tokenId The token id to mint.
   * @param _data bytes data to send along with a safe transfer check.
   * @return A boolean that indicates if the operation was successful.
   */
  function safeMint(address to, uint256 tokenId, bytes memory _data) public
  onlyMinter
  isNotPaused
  returns (bool) {
      _safeMint(to, tokenId, _data);
      return true;
  }



}
