const Token = artifacts.require("CHIPToken");
const Web3 = require("web3");
const web3 = new Web3();


contract("CHIPToken Tests", async (accounts) => {
    /* it("Owner should get 50% of the total tokens", function(){
        return Token.deployed()
            .then(function(instance){
                console.log("Contract deployed at: " + instance.address);
                return instance.balanceOf(accounts[0]).call()
            })
            .then(function(balance){
                console.log(balance);
                assert.equal(true);
            });
    }); */

    it("Owner should get 50% of the total tokens", async () => {
        let instance = await Token.deployed();
        let weiBalance = await instance.balanceOf(accounts[0]);
        let balance = web3.fromWei(weiBalance.toNumber(), "ether");
        //console.log("Contract deployed at: " + instance.address);
        //console.log("Balance " + balance);
        //console.log(balance);
        assert.equal(balance, "1000000000");
    });

    it("Admin should get 50% of the total tokens", async () => {
        let instance = await Token.deployed();
        let weiBalance = await instance.balanceOf(accounts[1]);
        let balance = web3.fromWei(weiBalance.toNumber(), "ether");
        assert.equal(balance, "1000000000");
    });

    it("Checks the admin address", async () => {
        let instance = await Token.deployed();
        const adminAddr = await instance.adminAddr();
        assert.equal(adminAddr, accounts[1]);
    })

    //it("Admin should get 50% of the total tokens")
});