const OpenVault = artifacts.require("OpenVault");

module.exports = function (deployer) {
  deployer.deploy(OpenVault);
};
