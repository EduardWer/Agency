var Faucet = artifacts.require("RealEstateAgency");

module.exports = function(deployer) {
  deployer.deploy(Faucet);
};