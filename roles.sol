pragma solidity ^0.5.5;

/**
 * @title Minters
 * @dev Library for managing addresses assigned to a Role.
 */
library Minters {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Minters: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Minters: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Minters: account is the zero address");
        return role.bearer[account];
    }
}
/**
 * @title blocks
 * @dev Library for managing addresses assigned to restriction.
 */

library blocks {

  struct Role{
    /// @dev Black Lists
    mapping (address => bool) bearer;
  }

  /**
   * @dev remove an account access to this contract
   */
  function add(Role storage role, address account) internal {
      require(!has(role, account),"blocks: account already has role");

      role.bearer[account] = true;
  }

  /**
   * @dev give back an blocked account's access to this contract
   */
  function remove(Role storage role, address account) internal {
      require(has(role, account), "blocks: account does not have role");

      role.bearer[account] = false;
  }

  /**
   * @dev check if an account has blocked to use this contract
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0), "blocks: account is the zero address");
      return role.bearer[account];
  }

}
