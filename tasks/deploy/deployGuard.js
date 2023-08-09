const { networks } = require("../../networks");

task("deploy-guard", "Deploys ProtectWithdrawl contract ").setAction(
  async (taskArgs, hre) => {
    console.log(`Deploying ProtectWithdrawl contract to ${network.name}`);

    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }
    const zora = await ethers.getContractFactory("ProtectWithdrawl");
    const zoraContract = await zora.deploy();
    console.log(
      `\nWaiting 3 blocks for transaction ${zoraContract.deployTransaction.hash} to be confirmed...`
    );

    await zoraContract.deployTransaction.wait(
      networks[network.name].WAIT_BLOCK_CONFIRMATIONS
    );
    console.log("\nVerifying contract...");
    try {
      await run("verify:verify", {
        address: zoraContract.address,
        constructorArguments: [],
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
      `ProtectWithdrawl deployed to ${zoraContract.address} on ${network.name}`
    );
  }
);
