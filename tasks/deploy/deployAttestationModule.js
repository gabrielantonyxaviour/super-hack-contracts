const { networks } = require("../../networks");

task("deploy-att-module", "Deploys MockAttestationModule contract ").setAction(
  async (taskArgs, hre) => {
    console.log(`Deploying AttestationModule contract to ${network.name}`);

    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }
    const zora = await ethers.getContractFactory("AttestationModule");
    const zoraContract = await zora.deploy(
      "0x4200000000000000000000000000000000000021",
      "0x515f06B36E6D3b707eAecBdeD18d8B384944c87f",
      "app_staging_8ba6b6491a27ba84a2255bcde4bcd3f3",
      "atestamint",
      "0xfB0A6b925d503D0a2c3Dc9890D77AdF1767eE3F6",
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
          "0x4200000000000000000000000000000000000021",
          "0x515f06B36E6D3b707eAecBdeD18d8B384944c87f",
          "app_staging_8ba6b6491a27ba84a2255bcde4bcd3f3",
          "atestamint",
          "0xfB0A6b925d503D0a2c3Dc9890D77AdF1767eE3F6",
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
