var Token = artifacts.require("./CHIPToken.sol");
var Sale = artifacts.require("./CHIPSale.sol");

Date.prototype.getUnixTime = function() { return this.getTime()/1000|0 };

module.exports = function(deployer, network, accounts) {
    let admin, fundingMin, fundingCap, rate, startTime, endTime;

    console.log("Deploying contracts on: " + network);
    if (network=="development"){

        admin=accounts[1];
        fundingMin = 0.001;
        fundingCap = 100;
        //minContribution = 0.001 * Math.pow(10, 18);
        rate=10000;
        startTime = new Date().getUnixTime();
        endTime = startTime + 2592000; // 30 days

    }else if(network=="rinkeby"){

        admin="0xc1c13ed18081b6b1a9f6caa9e519cdc42b895c78";
        fundingMin = 0.001;
        fundingCap = 999999999999;
        //minContribution = 0.001 * Math.pow(10, 18);
        rate=10000;
        startTime = new Date().getUnixTime();
        endTime = startTime + 2592000; // 30 days

    }else if(network=="mainnet"){

        admin="0x0f4eA45B015ac982380ede40F53c5208e697eDC1";
        fundingMin = 0.001;
        fundingCap = 999999999999;
        //minContribution = 0.001 * Math.pow(10, 18);
        rate=10000;
        startTime = new Date('Sun, 01 Apr 2018 00:00:00 GMT').getUnixTime();
        endTime = new Date('Thu, 01 Jan 2099 00:00:00 GMT').getUnixTime();
    
    }

    deployer.deploy(Token, admin).then(function() {
        return deployer.deploy(Sale, admin, fundingMin, fundingCap, startTime, endTime, rate, Token.address);
    });

};