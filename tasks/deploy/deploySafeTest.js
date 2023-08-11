const { networks } = require("../../networks");

task("deploy-safe-test", "Deploys SafeTest contract ").setAction(
  async (taskArgs, hre) => {
    console.log(`Deploying SafeTest contract to ${network.name}`);

    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }
    const safeTest = await ethers.getContractFactory("SafeTest");
    const safeImplementationAddress =
      networks[network.name].SAFE_IMPLEMENTATION;
    const safeProxyFactory = networks[network.name].SAFE_PROXY_FACTORY;
    const attestationModuleImplementation =
      networks[network.name].ATTESTATION_MODULE_IMPLEMENTATION;
    const guardImplementation = networks[network.name].GUARD_IMPLEMENTATION;

    console.log("SAFE IMPLEMENTATION: ", safeImplementationAddress);
    console.log("SAFE PROXY FACTORY: ", safeProxyFactory);
    console.log(
      "ATTESTATION MODULE IMPLEMENTATION: ",
      attestationModuleImplementation
    );
    console.log("GUARD IMPLEMENTATION: ", guardImplementation);
    const safeTestContract = await safeTest.deploy(
      safeProxyFactory,
      safeImplementationAddress,
      attestationModuleImplementation,
      guardImplementation
    );

    console.log(
      `\nWaiting ${
        networks[network.name].WAIT_BLOCK_CONFIRMATIONS
      } blocks for transaction ${
        safeTestContract.deployTransaction.hash
      } to be confirmed...`
    );

    await safeTestContract.deployTransaction.wait(
      networks[network.name].WAIT_BLOCK_CONFIRMATIONS
    );
    console.log("\nVerifying contract...");
    try {
      await run("verify:verify", {
        address: safeTestContract.address,
        constructorArguments: [
          safeProxyFactory,
          safeImplementationAddress,
          attestationModuleImplementation,
          guardImplementation,
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
      `SafeTest contract deployed to ${safeTestContract.address} on ${network.name}`
    );
  }
);
