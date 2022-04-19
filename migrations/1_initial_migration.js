const Strategy = artifacts.require(
  '../contracts/EpicStrategy_Avax_Curve_Aave.sol'
)

const Vault = artifacts.require(
  '../contracts/EpicVault.sol'
)

const REWARDS_ADDR = '0x000000000000000000000000000000000000dEaD';
const WANT = '0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664'; //USDC
const DECIMALS = 6;

module.exports = async (deployer, network, addresses) => {
  try {
    await deployer.deploy(Vault,  WANT, "CRVAAVE", DECIMALS, REWARDS_ADDR)
    await deployer.deploy(Strategy, Vault.address)
  } catch (err) {
    console.log('Contracts deployment failed. Error: ', err);
  }
}