/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a 
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() { 
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>') 
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */

require('dotenv').config();
const Web3 = require("web3");
const web3 = new Web3();
const WalletProvider = require("truffle-wallet-provider");
const Wallet = require('ethereumjs-wallet');

var mainNetPrivateKey = new Buffer(process.env["MAINNET_PRIVATE_KEY"], "hex");
var mainNetWallet = Wallet.fromPrivateKey(mainNetPrivateKey);
var mainNetProvider = new WalletProvider(mainNetWallet, "https://mainnet.infura.io/");

var ropstenPrivateKey = new Buffer(process.env["ROPSTEN_PRIVATE_KEY"], "hex");
var ropstenWallet = Wallet.fromPrivateKey(ropstenPrivateKey);
var ropstenProvider = new WalletProvider(ropstenWallet, "https://ropsten.infura.io/");
//var ropstenProvider = new WalletProvider(ropstenWallet, "http://127.0.0.1:8080/");

var rinkebyPrivateKey = new Buffer(process.env["RINKEBY_PRIVATE_KEY"], "hex");
var rinkebyWallet = Wallet.fromPrivateKey(rinkebyPrivateKey);
var rinkebyProvider = new WalletProvider(rinkebyWallet, "https://rinkeby.infura.io/");


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      gas: 6700000,
      //from: "0x2abdf05db2c9632ab240ee59963816f09e6d3e5a",
      network_id: "*" // Match any network id
    },
    ropsten: {
      provider: ropstenProvider,
      // You can get the current gasLimit by running
      // truffle deploy --network rinkeby
      // truffle(rinkeby)> web3.eth.getBlock("pending", (error, result) =>
      //   console.log(result.gasLimit))
      gas: 4700000,
      gasPrice: web3.toWei("5", "gwei"),
      network_id: "3",
    },
    rinkeby: {
      provider: rinkebyProvider,
      gas: 6700000,
      gasPrice: web3.toWei("10", "gwei"),
      network_id: "2",
    },
    mainnet: {
      provider: mainNetProvider,
      gas: 2700000,
      gasPrice: web3.toWei("15", "gwei"),
      network_id: "1",
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};



