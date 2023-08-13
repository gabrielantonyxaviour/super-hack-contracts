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
    const eas = networks[network.name].EAS_DEPLOYMENT;
    const worldId = networks[network.name].WORLDID_ROUTER;
    const appId = process.env.WORLDCOIN_APP_ID;
    const actionId = "atestamint";
    const schemaId =
      "0xae694f9e713ed68fabb42e4d75e15282c1db63887a06df4a78ca3c91a444fc14";
    const vaultContract = await vault.deploy(
      eas,
      worldId,
      appId,
      actionId,
      taskArgs.atestamint,
      schemaId,
      {
        gasPrice: 50000,
      }
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
        constructorArguments: [
          eas,
          worldId,
          appId,
          actionId,
          atestamint,
          schemaId,
        ],
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
