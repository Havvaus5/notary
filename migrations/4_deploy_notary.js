let Owner = artifacts.require("./Owner.sol");
let RealEstate = artifacts.require("./RealEstate.sol");
let RealEstateOwnerRelation = artifacts.require("./RealEstateOwnerRelation.sol");

module.exports = async function(deployer) {
    await deployer.deploy(Owner);
    const ownInstance = await Owner.deployed();

    await deployer.deploy(RealEstate);
    const realEstateInstance = await RealEstate.deployed();
    await deployer.deploy(RealEstateOwnerRelation, ownInstance.address, realEstateInstance.address);
    
};