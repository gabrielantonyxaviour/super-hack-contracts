require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;

const networks = {
  polygonMumbai: {
    url: process.env.POLYGON_MUMBAI_RPC_URL || "UNSET",
    gasPrice: undefined,
    accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
    verifyApiKey: process.env.POLYGONSCAN_API_KEY || "UNSET",
    chainId: 80001,
    nativeCurrencySymbol: "MATIC",
  },
};

module.exports = {
  networks,
};
