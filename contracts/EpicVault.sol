// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/nuke/EpicStrategy.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract EpicVault is ERC20, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    address public governance;
    address public strategy;
    address public rewards;

    event PPS(uint256 pps);

    constructor(address _token, string memory _tokenName, uint8 _decimals, address _rewards)
        public
        ERC20(
            string(abi.encodePacked("Nuke Epic Vault ", _tokenName)),
            string(abi.encodePacked("nuke", _tokenName))
        )
    {
        _setupDecimals(_decimals);
        token = IERC20(_token);
        governance = msg.sender;
        rewards = _rewards;

    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(EpicStrategy(strategy).balanceOf());
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setRewards(address _rewards) public {
        require(msg.sender == governance, "!governance");
        rewards = _rewards;
    }

    function setStrategy(address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(EpicStrategy(_strategy).want() == address(token), "!token");

        address _current = strategy;
        if (_current != address(0)) {
            EpicStrategy(_current).withdrawAll();
        }
        strategy = _strategy;
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(msg.sender == governance, "!governance");
        require(_token != address(token), "token");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function earn() public {
        require(msg.sender == governance, "!governance");
        token.safeTransfer(strategy, token.balanceOf(address(this)));
        EpicStrategy(strategy).deposit();
        emit PPS(getPricePerFullShare());
    }

    function depositAll() public whenNotPaused {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public whenNotPaused {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens

        uint256 shares = 0;
        token.safeTransfer(strategy, _amount);
        EpicStrategy(strategy).deposit();
        uint256 _finalAmount = balance().sub(_pool);

        if (totalSupply() == 0) {
            shares = _finalAmount;
        } else {
            shares = (_finalAmount.mul(totalSupply())).div(_pool);
        }

        _mint(msg.sender, shares);
    }

    function withdrawAll() external whenNotPaused {
        withdraw(balanceOf(msg.sender));
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint256 _shares) public whenNotPaused {
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            EpicStrategy(strategy).withdraw(_withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, r);
    }

    function getPricePerFullShare() public view returns (uint256) {
        return balance().mul(1e18).div(totalSupply());
    }

    /// @dev Pause the contract
    function pause() external {
        require(msg.sender == governance, "!governance");
        _pause();
    }

    /// @dev Unpause the contract
    function unpause() external {
        require(msg.sender == governance, "!governance");
        _unpause();
    }

}
