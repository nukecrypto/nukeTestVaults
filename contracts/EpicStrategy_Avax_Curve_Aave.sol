// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/uniswap/Uni.sol";
import "../interfaces/curve/ICurve.sol";
import "../interfaces/nuke/IEpicVault.sol";

contract EpicStrategy_Avax_Curve_Aave{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    //tokens needed
    address public constant CRV = 0x47536F17F4fF30e64A96a7555826b8f9e66ec468; //CRV
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address public constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    address public constant CURVE_LP_TOKEN = 0x1337BedC9D22ecbe766dF105c9623922A27963EC; //Curve.fi avDAI/avUSDC/avUSDT (av3CRV)

    //The token we deposit into the Pool
    address public constant want = USDC;

    //The reward
    address public reward = CRV;

    // We add liquidity here
    address public constant CURVE_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address public GAUGE = 0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858; //GAUGE CONTROLLER

    address public constant SUSHISWAP_ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

    uint256 public constant MAX_BPS = 10000;
    uint256 public sl = 100;

    uint256 public performanceFee = 1000;
    uint256 public constant performanceMax = 10000;

    uint256 public withdrawalFee = 50;
    uint256 public constant withdrawalMax = 10000;

    address public governance;
    address public strategist;
    address public vault;

    uint256 public lifetimeEarned = 0;

    event Harvest(uint256 wantEarned, uint256 lifetimeEarned);

    constructor(address _vault) public {
        governance = msg.sender;
        strategist = msg.sender;
        vault = _vault;

    }

    function doApprovals() public {
        IERC20(CURVE_LP_TOKEN).safeApprove(GAUGE, type(uint256).max);
        IERC20(reward).safeApprove(SUSHISWAP_ROUTER,type(uint256).max);
        IERC20(WAVAX).safeApprove(SUSHISWAP_ROUTER,type(uint256).max);
        IERC20(USDC).safeApprove(CURVE_POOL, type(uint256).max);
    }

    function getName() external pure returns (string memory) {
        return "EpicStrategy_Avax_Curve_Aave";
    }

    /// @dev Balance of want currently held in strategy positions
    function balanceOfPool() public view returns (uint256) {
        //Balance of Curve LP
        uint256 amountCRVLP = IERC20(GAUGE).balanceOf(address(this));

        if (amountCRVLP > 0) {

            //Balance of USDC / this is taking into account fees...
            uint256 amountUSDC = ICurveStableSwapAave(CURVE_POOL).calc_withdraw_one_coin(amountCRVLP, 1);

            return amountUSDC;
        } else {
            return 0;
        }

    }

    function balanceOf() public virtual view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function deposit() public {

        //Add USDC liquidity into CURVE
        ICurveStableSwapAave(CURVE_POOL).add_liquidity(
            [0, IERC20(USDC).balanceOf(address(this)), 0],
            0,
            true
        );

        uint256 _balCRVLP = IERC20(CURVE_LP_TOKEN).balanceOf(address(this));

        require(_balCRVLP > 0, "!_balCRVLP");

        ICurveGauge(GAUGE).deposit(_balCRVLP);
    }


    function _withdrawSome(uint256 _amount) internal returns (uint256) {

        if (_amount > balanceOfPool()) {
            _amount = balanceOfPool();
        }

        uint256 _before = IERC20(want).balanceOf(address(this));

        //Figure out how many CRVLP
        uint256 _amountNeededCRVLP = ICurveStableSwapAave(CURVE_POOL).calc_token_amount([0, _amount, 0], false);

        //check that we have enough
        uint256 _amountCRVLP = IERC20(GAUGE).balanceOf(address(this));
        if (_amountNeededCRVLP > _amountCRVLP) {
            _amountNeededCRVLP = _amountCRVLP;
        }

        ICurveGauge(GAUGE).withdraw(_amountNeededCRVLP);
        //WD from CURVE_POOL
        ICurveStableSwapAave(CURVE_POOL).remove_liquidity_one_coin(
            IERC20(CURVE_LP_TOKEN).balanceOf(address(this)),
            1,
            0,
            true
        );

        uint256 _after = IERC20(want).balanceOf(address(this));
        return _after.sub(_before);
    }

    function _withdrawAll() internal {
        //Balance of CLP_TOKEN
        uint256 _amountCRVLP = IERC20(GAUGE).balanceOf(address(this));
        if(_amountCRVLP > 0) {
            //WD from CURVE_GAUGE
            ICurveGauge(GAUGE).withdraw(_amountCRVLP);
            //WD from CURVE_POOL
            ICurveStableSwapAM3CRV(CURVE_POOL).remove_liquidity_one_coin(
                IERC20(CURVE_LP_TOKEN).balanceOf(address(this)),
                1,
                0,
                true
            );
        }

    }

    function harvest() public {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");

        uint256 _before = IERC20(USDC).balanceOf(address(this));

        // figure out and claim our rewards
        ICurveGauge(GAUGE).claim_rewards();

        uint256 rewardsToReinvest1 = IERC20(reward).balanceOf(address(this)); //CRV
        if (rewardsToReinvest1 > 0) {
            address[] memory pathA = new address[](2);
            pathA[0] = reward;
            pathA[1] = WAVAX;
            IUniswapRouterV2(SUSHISWAP_ROUTER).swapExactTokensForTokens(
                rewardsToReinvest1,
                0,
                pathA,
                address(this),
                now
            );
        }

        uint256 rewardsToReinvest2 = IERC20(WAVAX).balanceOf(address(this)); //WAVAX
        if (rewardsToReinvest2 > 0) {
            address[] memory pathB = new address[](2);
            pathB[0] = WAVAX;
            pathB[1] = USDC;
            IUniswapRouterV2(SUSHISWAP_ROUTER).swapExactTokensForTokens(
                rewardsToReinvest2,
                0,
                pathB,
                address(this),
                now
            );
        }


        uint256 earned = IERC20(USDC).balanceOf(address(this)).sub(_before);

        /// @notice Keep this in so you get paid!
        if (earned > 0) {
            uint256 _fee = earned.mul(performanceFee).div(performanceMax);
            IERC20(USDC).safeTransfer(IEpicVault(vault).rewards(), _fee);
        }

        lifetimeEarned = lifetimeEarned.add(earned);

        /// @dev Harvest event that every strategy MUST have, see BaseStrategy
        emit Harvest(earned, lifetimeEarned);

        deposit();

    }


    //******************************
    // No need to change
    //******************************

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVault(address _vault) external {
        require(msg.sender == governance, "!governance");
        vault = _vault;
    }

    function setSlippageTolerance(uint256 _s) external {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        sl = _s;
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == vault, "!vault");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(vault, balance);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);

        //We removed the transfer of the fee to instead stay within the strategy,
        //therefor any fees generated by the withdrawal fee will be of benefit of all vault users
        //IERC20(want).safeTransfer(IController(controller).rewards(), _fee);

        IERC20(want).safeTransfer(vault, _amount.sub(_fee));
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == vault, "!vault");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));
        if (balance > 0) {
            IERC20(want).safeTransfer(vault, balance);
        }
    }

}