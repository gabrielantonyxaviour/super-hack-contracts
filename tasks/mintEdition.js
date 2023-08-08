const { networks } = require("../networks");
task("mint-edition", "Mints an edition of the Zora NFT to the minter")
  .addParam("amount", "Amount of tokens to be minted")
  .setAction(async (taskArgs, hre) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }

    console.log(`Minting ${taskArgs.amount} tokens to the caller`);
    try {
      const zoraContractFactory = await ethers.getContractFactory("Zora");
      const zoraContract = await zoraContractFactory.attach(
        "0xE35962CB065eda20E7b9aa222173b08c48Cc886f"
      );
      const mintNftTx = await zoraContract.mintEdition(
        "0x478265671e078C56250c7cFd121B8E3551eFD18B",
        taskArgs.amount
      );
      // console.log(`\nWaiting 3 blocks for transaction ${binderContract.deployTransaction.hash} to be confirmed...`)
      const mintNftTxHash = await mintNftTx.wait(3);
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
  });
