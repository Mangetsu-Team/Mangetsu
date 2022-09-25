// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Mangetsu.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract MangetsuToken is Mangetsu {

    IERC20 public token;
    constructor(
        IVerifier _verifier,
        IHasher _hasher,
        uint256 _denomination,
        uint32 _merkleTreeHeight,
        IERC20 _token
      ) Mangetsu(_verifier, _hasher, _denomination, _merkleTreeHeight) {
        token = _token;
    }

    function _processDeposit() internal override {
        require(msg.value == 0, "ETH value is supposed to be 0 for ERC20 instance");
        token.transferFrom(msg.sender, address(this), denomination);
    }

    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
      ) internal /* override */ {
        require(msg.value == _refund, "Incorrect refund amount received by the contract");
    
        token.transfer(_recipient, denomination - _fee);
        if (_fee > 0) {
            token.transfer(_relayer, _fee);
        }
    
        if (_refund > 0) {
            (bool success, ) = _recipient.call{ value: _refund }("");
            if (!success) {
                // let's return _refund back to the relayer
                _relayer.transfer(_refund);
            }
        }
    }
}