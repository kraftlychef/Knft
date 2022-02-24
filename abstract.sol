pragma solidity ^0.5.5;
/**
 * @dev Interface of the TRC165 standard.
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({TRC165Checker}).
 *
 * For an implementation, see {TRC165}.
 */
interface ITRC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




/**
 * @dev Required interface of an TRC721 compliant contract.
 */
contract ITRC721 is ITRC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


/**
 * @title TRC-721 Non-Fungible Token Standard, optional metadata extension
 */
contract ITRC721Metadata is ITRC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
/**
 * @title TRC-721 Non-Fungible Token Standard, optional enumeration extension
 */
contract ITRC721Enumerable is ITRC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

//interface of TRC721 contract name
contract IKraftNft is ITRC721Metadata,ITRC721Enumerable{

}

/**
 * @title TRC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from TRC721 asset contracts.
 */
contract ITRC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The TRC721 smart contract calls this function on the recipient
     * after a {ITRC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onTRC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the TRC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onTRC721Received(address,address,uint256,bytes)"))`
     */
    function onTRC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}
