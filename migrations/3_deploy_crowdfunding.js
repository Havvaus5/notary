const Crowdfunding = artifacts.require('./Crowdfunding.sol')

module.exports = function(deployer) {
  deployer.deploy(
    Crowdfunding,
    'Test campaign',
    1,
    5 * 24 * 60, // 5 days
    '0x02490AE8E8198ad2cF659241b1d708B2C497B2C5'
  )
}