const { networks } = require("../../networks");

task("deploy-vault", "Deploys Vault contract ").setAction(
  async (taskArgs, hre) => {
    console.log(`Deploying Vault contract to ${network.name}`);

    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }
    const vault = await ethers.getContractFactory("Vault");
    const eas = "0x4200000000000000000000000000000000000021";
    const worldId = "0x515f06B36E6D3b707eAecBdeD18d8B384944c87f";
    const appId = "app_staging_8ba6b6491a27ba84a2255bcde4bcd3f3";
    const actionId = "atestamint";
    const atestamint = "0x9DbB3Bd263E9C782f5784a73418580b455D2e6df";
    const vaultContract = await vault.deploy(
      eas,
      worldId,
      appId,
      actionId,
      atestamint
    );

    console.log(
      `\nWaiting 3 blocks for transaction ${vaultContract.deployTransaction.hash} to be confirmed...`
    );

    await vaultContract.deployTransaction.wait(
      networks[network.name].WAIT_BLOCK_CONFIRMATIONS
    );
    console.log("\nVerifying contract...");
    try {
      await run("verify:verify", {
        address: vaultContract.address,
        constructorArguments: [eas, worldId, appId, actionId, atestamint],
      });
      console.log("Contract verified");
    } catch (error) {
      if (!error.message.includes("Already Verified")) {
        console.log(
          "Error verifying contract.  Delete the build folder and try again."
        );
        console.log(error);
      } else {
        console.log("Contract already verified");
      }
    }
    console.log(
      `Vault deployed to ${vaultContract.address} on ${network.name}`
    );
  }
);
