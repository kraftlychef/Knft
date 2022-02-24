pragma solidity ^0.5.5;


library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 tokenIds and owners.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _tokenId;
        bytes32 _owner;
    }

    struct UintToAddressMap {
        // Storage of map tokenIds and owners
        MapEntry[] _entries;

        // Position of the entry defined by a tokenId in the `entries` array, plus 1
        // because index 0 means a tokenId is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a tokenId-owner pair to a map, or updates the owner for an existing
     * tokenId. O(1).
     *
     */

    function set(UintToAddressMap storage map, uint256 tokenId, address owner) internal {

        bytes32 _TokenIdInBytes = bytes32(tokenId);
        bytes32 _ownerInBytes = bytes32(uint256(owner));

        // We read and store the tokenId's index to prevent multiple reads from the same storage slot
        uint256 tokenIdIndex = map._indexes[_TokenIdInBytes];

        if (tokenIdIndex == 0) { // Equivalent to !contains(map, tokenId)
            map._entries.push(MapEntry({ _tokenId: _TokenIdInBytes, _owner: _ownerInBytes }));
            // The entry is stored at length-1, but we add 1 to all indexes
            map._indexes[_TokenIdInBytes] = map._entries.length;
        } else {
            map._entries[tokenIdIndex - 1]._owner = _ownerInBytes;
        }
    }
    /**
     * @dev Removes a owner from a set. O(1).
     *
     * Returns true if the tokenId was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 tokenId) internal {
      bytes32 _TokenIdInBytes = bytes32(tokenId);

        // We read and store the tokenId's index to prevent multiple reads from the same storage slot
        uint256 tokenIdIndex = map._indexes[_TokenIdInBytes];
        require(tokenIdIndex != 0,"EnumerableMap: remove tokenId is nonexistent");

            // To delete a tokenId-owner pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = tokenIdIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._tokenId] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[_TokenIdInBytes];

    }

    /**
     * @dev Returns true if the tokenId is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 tokenId) internal view returns (bool) {
        return map._indexes[bytes32(tokenId)] != 0;
    }

    /**
     * @dev Returns the number of tokenId-owner pairs in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the tokenId-owner pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */

     function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
         require(map._entries.length > index, "EnumerableMap: index out of bounds");

         MapEntry storage entry = map._entries[index];
         return (uint256(entry._tokenId), address(uint256(entry._owner)));
     }

    /**
     * @dev Returns the owner associated with `tokenId`.  O(1).
     *
     * Requirements:
     *
     * - `tokenId` must be in the map.
     */


    function get(UintToAddressMap storage map, uint256 tokenId) internal view returns (address) {
        return _get(map, tokenId, "EnumerableMap: nonexistent tokenId");
    }
    /**
     * @dev Same as {get}, with a custom error message when `tokenId` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 tokenId, string memory errorMessage) internal view returns (address) {
        return _get(map, tokenId, errorMessage);
        return address(uint256(_get(map, tokenId, errorMessage)));
    }

    /**
     * @dev Same as {_get}, with a custom error message when `tokenId` is not in the map.
     */
    function _get(UintToAddressMap storage map, uint256 tokenId, string memory errorMessage) private view returns (address) {
        uint256 tokenIdIndex = map._indexes[bytes32(tokenId)];
        require(tokenIdIndex != 0, errorMessage); // Equivalent to contains(map, tokenId)
        return address(uint256(map._entries[tokenIdIndex - 1]._owner));
    }




}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // uint256 tokenIds.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct UintSet {
        // Storage of set tokenIds
        uint256[] _ownedTokens;

        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) _ownedTokensIndex;
    }

    /**
     * @dev Add a tokenId to a set. O(1).
     *
     * Returns true if the tokenId was added to the set, that is if it was not
     * already present.
     */

    function add(UintSet storage set, uint256 tokenId) internal{
      require(!_contains(set, tokenId),"EnumerableSet: tokenId already contain");
      set._ownedTokens.push(tokenId);
      // The tokenId is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel tokenId
      set._ownedTokensIndex[tokenId] = set._ownedTokens.length;
    }


    /**
     * @dev Removes a tokenId from a set. O(1).
     *
     * Returns true if the tokenId was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 tokenId) internal{
      require(_contains(set, tokenId),"EnumerableSet: tokenId not belongs to owner");
      // We read and store the tokenId's index to prevent multiple reads from the same storage slot
      uint256 tokenIdIndex = set._ownedTokensIndex[tokenId];
      // To delete an element from the _ownedTokens array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = tokenIdIndex - 1;
      uint256 lastIndex = set._ownedTokens.length - 1;

      // When the tokenId to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      uint256 lasttokenId = set._ownedTokens[lastIndex];

      // Move the last tokenId to the index where the tokenId to delete is
      set._ownedTokens[toDeleteIndex] = lasttokenId;
      // Update the index for the moved tokenId
      set._ownedTokensIndex[lasttokenId] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved tokenId was stored
      set._ownedTokens.pop();

      // Delete the index for the deleted slot
      delete set._ownedTokensIndex[tokenId];

    }
    /**
     * @dev Returns true if the tokenId is in the set. O(1).
     */
    function _contains(UintSet storage set, uint256 tokenId) private view returns (bool) {
        return set._ownedTokensIndex[tokenId] != 0;
    }
    /**
     * @dev Returns true if the tokenId is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 tokenId) internal view returns (bool) {
      return _contains(set,tokenId);
    }
    /**
     * @dev Returns all tokenIds of owner.
     * WARNING call can be vast sometime , use it with caution
     */
    function all(UintSet storage set) internal view returns (uint256 [] memory) {
      return set._ownedTokens;
    }

    /**
     * @dev Returns the number of tokenIds on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return set._ownedTokens.length;
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
      require(set._ownedTokens.length > index, "EnumerableSet: index out of bounds");
      return set._ownedTokens[index];
    }
}
/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
