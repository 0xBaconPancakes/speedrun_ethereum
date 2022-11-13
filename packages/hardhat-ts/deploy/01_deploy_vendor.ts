import { DeployFunction } from 'hardhat-deploy/types';
import { parseEther } from 'ethers/lib/utils';
import { HardhatRuntimeEnvironmentExtended } from 'helpers/types/hardhat-type-extensions';
import { ethers } from 'hardhat';

const func: DeployFunction = async (hre: HardhatRuntimeEnvironmentExtended) => {
  const { getNamedAccounts, deployments } = hre as any;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // You might need the previously deployed yourToken:
  const yourToken = await ethers.getContract('YourToken', deployer);

  await deploy('Vendor', {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [yourToken.address],
    log: true,
  });

  const vendor = await ethers.getContract("Vendor", deployer);

  console.log("\n 🏵  Sending all 1000 tokens to the vendor...\n");

  await yourToken.transfer(
    vendor.address,
    ethers.utils.parseEther("1000")
  );

  await vendor.transferOwnership("0xDe0476793ff6BBf931B5FD8586E275B43Be195C2");
};
export default func;
func.tags = ['Vendor'];
