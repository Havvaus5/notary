let Owner = artifacts.require("./Owner.sol");
let RealEstate = artifacts.require("./RealEstate.sol");
let RealEstateOwnerRelation = artifacts.require("./RealEstateOwnerRelation.sol");
let HissedarOnay = artifacts.require("./HissedarOnay.sol");
let RealEstateSaleAd = artifacts.require("./RealEstateSaleAd.sol");
let Proposition = artifacts.require("./Proposition.sol");

module.exports = async function(deployer) {
    await deployer.deploy(Owner);
    const ownInstance = await Owner.deployed();

    await deployer.deploy(RealEstate);
    const realEstateInstance = await RealEstate.deployed();
    await deployer.deploy(RealEstateOwnerRelation, realEstateInstance.address, ownInstance.address);

    const realEstateOwnerRelInstance = await RealEstateOwnerRelation.deployed();
    
    await deployer.deploy(HissedarOnay, realEstateOwnerRelInstance.address, realEstateInstance.address);
    const hissedarOnayIns = await HissedarOnay.deployed();
    await deployer.deploy(RealEstateSaleAd, ownInstance.address, realEstateOwnerRelInstance.address, realEstateInstance.address, hissedarOnayIns.address);
    
    const adInstance = await RealEstateSaleAd.deployed();
    await deployer.deploy(Proposition, adInstance.address);
};