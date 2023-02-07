// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NotaryContractBase.sol";

contract RealEstate is NotaryContractBase {
    mapping(uint256 => RealEstateData) realEstateMap;
    mapping(uint256 => uint256) realEstaIDRealEstateHashMap;
    uint[] realEstateLUT;

    event RealEstateAddedToSystem(uint256 realEstateId);

    function addRealEstate(RealEstateData memory reData) public {
        uint256 realEstateId = hashRealEstate(reData); //TODO bilgilerin daha önceden olmadığını kontrol et
        uint256 blkZamn = block.timestamp;
        reData.registered = true;
        reData.realEstateId = realEstateId;
        realEstaIDRealEstateHashMap[realEstateId] = blkZamn;
        realEstateMap[blkZamn] = reData;
        realEstateLUT.push(blkZamn);
        emit RealEstateAddedToSystem(blkZamn);
    }

    function listAllRealestate() public view returns(RealEstateData[] memory){
         RealEstateData [] memory result = new RealEstateData[](realEstateLUT.length);
         for (uint i = 0; i < realEstateLUT.length; i++) {
            result[i] = realEstateMap[realEstateLUT[i]];
         }
         return result;
    }

    function getRealEstateLUT() public view returns(uint[] memory){
        return realEstateLUT;
    }

    function isRealEstateRegisted(uint256 realEstateId)
        public
        view
        returns (bool)
    {
        return realEstateMap[realEstateId].registered;
    }

    function getRealEstatePayda(uint256 realEstateId)
        public
        view
        returns (uint256)
    {
        return realEstateMap[realEstateId].payda;
    }

    function getRealEstateInfo(uint256 realEstateId)
        public
        view
        returns (RealEstateData memory)
    {
        return realEstateMap[realEstateId];
    }

    function hashRealEstate(RealEstateData memory reData)
        public
        pure
        returns (uint256)
    {
        uint256 realEstateId = uint256(
            keccak256(
                abi.encodePacked(
                    reData.il,
                    reData.ilce,
                    reData.mahalle,
                    reData.cadde,
                    reData.sokak,
                    reData.kat,
                    reData.daireNo,
                    reData.tasinmazTip,
                    reData.nitelik,
                    reData.ada,
                    reData.parsel
                )
            )
        );

        return realEstateId;
    }

    function getId(RealEstateData memory reData) public view returns (uint256) {
        uint256 realEstateId = hashRealEstate(reData);
        return realEstaIDRealEstateHashMap[realEstateId];
    }

}
