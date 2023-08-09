const { networks } = require("../../networks");

task("deploy-safe-test", "Deploys SafeTest contract ").setAction(
  async (taskArgs, hre) => {
    console.log(`Deploying SafeTest contract to ${network.name}`);

    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }
    const zora = await ethers.getContractFactory("SafeTest");
    const zoraFactoryAddress = networks[network.name].SAFE_IMPLEMENTATION;
    const attestationModuleImplementation =
      "0xFFaFc5fEF5A0Fd9b0137B464BE69A85Ae4bfDc36";
    const zoraContract = await zora.deploy(
      zoraFactoryAddress,
      attestationModuleImplementation
    );
    console.log(
      `\nWaiting ${
        networks[network.name].WAIT_BLOCK_CONFIRMATIONS
      } blocks for transaction ${
        zoraContract.deployTransaction.hash
      } to be confirmed...`
    );

    await zoraContract.deployTransaction.wait(
      networks[network.name].WAIT_BLOCK_CONFIRMATIONS
    );
    console.log("\nVerifying contract...");
    try {
      await run("verify:verify", {
        address: zoraContract.address,
        constructorArguments: [
          zoraFactoryAddress,
          attestationModuleImplementation,
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
      `SafeTest contract deployed to ${zoraContract.address} on ${network.name}`
    );
  }
);
