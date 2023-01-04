// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract RealEstate {

    struct RealEstateData {
        uint realEstateId;
       // string il;
        //string ilce;
        string mahalle;
        //string tasinmazTip;
        //string nitelik; //TODO enum
        //string ada;
        //string parsel;
        uint payda;
        bool registered;
        
    }

    mapping(uint => RealEstateData) realEstateMap; 

    function addRealEstate(string memory mahalle, uint payda) public{
        uint realEstateId=uint(keccak256(bytes(mahalle))); //TODO bilgilerin daha önceden olmadığını kontrol et
        realEstateMap[realEstateId] = RealEstateData(realEstateId, mahalle, payda, true);
    }

    function isRealEstateRegisted(uint realEstateId) public view returns(bool){
        return realEstateMap[realEstateId].registered;
    }
  
    function getRealEstatePayda(uint realEstateId) public view returns(uint){
        return realEstateMap[realEstateId].payda;
    }

    function getRealEstateInfo(uint realEstateId) public view returns(string memory) {
        return realEstateMap[realEstateId].mahalle;
    }

    function getId(string memory mahalle) public pure returns(uint){
        uint realEstateId=uint(keccak256(bytes(mahalle)));
        return realEstateId;
    }
    
}