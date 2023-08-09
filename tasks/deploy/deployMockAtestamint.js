const { networks } = require("../../networks");

task("deploy-mock-atestamint", "Deploys MockAtestamint contract ").setAction(
  async (taskArgs, hre) => {
    console.log(`Deploying MockAtestamint contract to ${network.name}`);

    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }
    const zora = await ethers.getContractFactory("MockAtestamint");
    const zoraFactory = networks[network.name].ZORA_NFT_CREATOR_PROXY;
    const safeImplementation = networks[network.name].SAFE_IMPLEMENTATION;
    const guardImplementation = "0xeD7B819cde5C9aE1BC529268e9aebb370bc5B84a";
    const moduleImplementation = "0xb65B773d773c7a7f2F378C71787Db7d7c32f687c";
    const zoraContract = await zora.deploy(
      zoraFactory,
      safeImplementation,
      guardImplementation,
      moduleImplementation,
      { gasPrice: 300000 }
    );
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
        constructorArguments: [
          zoraFactory,
          safeImplementation,
          guardImplementation,
          moduleImplementation,
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
      `AttestationModule deployed to ${zoraContract.address} on ${network.name}`
    );
  }
);
