// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./BEP20.sol";
contract  IBEP201 is BEP20{
  function _mint(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
        emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
    }
   function _beforeTokenTransfer( address from,address to,uint256 amount) internal virtual {}

    function _afterTokenTransfer( address from, address to,  uint256 amount) internal virtual {}
}