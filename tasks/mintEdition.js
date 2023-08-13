const { networks } = require("../networks");
task("mint-edition", "Mints an edition of the Zora NFT to the minter")
  .addParam("nft", "Address of the NFT collection to purchase")
  .setAction(async (taskArgs, hre) => {
    if (network.name === "hardhat") {
      throw Error(
        'This command cannot be used on a local development chain.  Specify a valid network or simulate an Functions request locally with "npx hardhat functions-simulate".'
      );
    }

    try {
      // const functionHash = ethers.utils.id("purchase(uint256)");
      // console.log(functionHash.slice(0, 10));
      // const data =
      //   functionHash.slice(0, 10) +
      //   ethers.utils.defaultAbiCoder.encode(["uint256"], [1]).slice(2);
      // const mintNftTx = await ethers.provider.sendTransaction({
      //   to: taskArgs.nft,
      //   data: data,
      //   value: ethers.utils.parseEther("0.000877"),
      //   gasPrice: 100000,
      // });
      // console.log(mintNftTx);

      const functionHash = ethers.utils.id("unlockFunds()").slice(0, 10);
      console.log(functionHash);

      // const functionHash = ethers.utils
      //   .id("vote(uint256,string,bool,address,uint256,uint256,uint256[8])")
      //   .slice(0, 10);

      // const encodedData = ethers.utils.defaultAbiCoder
      //   .encode(
      //     [
      //       "uint256",
      //       "string",
      //       "bool",
      //       "address",
      //       "uint256",
      //       "uint256",
      //       "uint256[8]",
      //     ],
      //     [
      //       1,
      //       "I really love this collection",
      //       true,
      //       "0x64574dDbe98813b23364704e0B00E2e71fC5aD17",
      //       "6833028050507396323949580117840016177554215485091593526212095878502963106228",
      //       "20114014021221598868561996055058381326823765294762422717146686596630909213884",
      //       [
      //         "497028577221633456142497513701153425063491683502133092469022359562190374744",
      //         "16586060915189931077371395804517903270218928658478884569386578518604733562372",
      //         "5151700307576585334945889721735983415404594992788110664487274165688684405080",
      //         "10467753472538414424479310631172913447541488272203854476588785358842380565224",
      //         "12930401476886026646010877537198442597306252823647730936571089471915757600702",
      //         "1532631506817304159443372884434260536983528862356176679528947720856950794612",
      //         "18229592846109042514945194896329466567915307963150127165134236355833329580693",
      //         "2418144585853607853789971853062904303330569278193512423321558653214032343964",
      //       ],
      //     ]
      //   )
      //   .slice(2);

      // const data = functionHash + encodedData;
      // console.log(data);

      // const result = await ethers.provider.call({
      //   to: taskArgs.nft,
      //   data: ethers.utils.id("royaltyMintSchedule()").slice(0, 10),
      // });
      // // console.log(result);
      // const value = ethers.utils.defaultAbiCoder.decode(
      //   ["uint256"],
      //   "0x2c7820e539ac12d55456cefda0f196cd8c2e878fd38fd6bcc34511fef47adcbc"
      // );
      // console.log(value);
      // console.log(value);
      // console.log(`\nWaiting 3 blocks for transaction ${binderContract.deployTransaction.hash} to be confirmed...`)
      // const mintNftTxHash = await mintNftTx.wait(3);
    } catch (error) {
      console.log(error);
    }
  });
