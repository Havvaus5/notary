// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstateOwnerRelation.sol";

contract RealEstateSaleAd {

    RealEstateOwnerRelation realEstateOwnerRelation;

    enum State {
        YAYINDA,
        ALICI_ICIN_KILITLENDI,
        YAYINDAN_KALDIRILDI
    }

    event ilanOlusturuldu(uint hisseId, address saticiId, uint ilanId, uint fiyat);
    event ilanYayindanKaldirildi(uint hisseId, address saticiId, uint ilanId);
    event aliciIcinKilitlendi(uint ilanId, address saticiId, address aliciId);    
    event fiyatDegistir(uint ilanId, uint yeniSatisFiyat, address saticiId);

    struct Advertisement{
        uint hisseId;        
        address satici;
        address alici;
        State  state;
        uint256  rayicBedeli;
        uint256  fiyat; //todo double 
        bool  borcuVarMi;
    }

    mapping (uint => Advertisement) adIdMap;
    mapping (uint => uint) hisseIdAdIdMap;
    mapping (address => uint[]) ownerAdIdListMap;
    uint[] adIdLUT;

    constructor(address realOwnRelAdd)  {
        //ownerContract=Owner(ownerContractAdd);
        realEstateOwnerRelation=RealEstateOwnerRelation(realOwnRelAdd);
    }

    function isHisseYayindaMi(uint hisseId) public view returns(uint){
        return hisseIdAdIdMap[hisseId];
    }

    function ilanOlustur(uint hisseId, uint256 rayicBedeli, uint256 satisFiyat, bool borcuVarMi) public {
        require(realEstateOwnerRelation.hisseSatisaCikabilirMi(hisseId, msg.sender), "Hisse sistemde yok");
        require(hisseIdAdIdMap[hisseId] != 0, "advertisement for real estate already exist in the system");
        require(rayicBedeli <= satisFiyat, "Satis fiyat rayic bedelden dusuk olamaz");
        require(borcuVarMi, "Gayrimenkulun vergi borcu olmaz");

        uint ilanId = block.timestamp;
        Advertisement memory ad = Advertisement(hisseId, msg.sender, address(0), State.YAYINDA, rayicBedeli, satisFiyat, borcuVarMi);
        adIdMap[ilanId] = ad;
        hisseIdAdIdMap[hisseId] = ilanId;
        adIdLUT.push(ilanId);
        ownerAdIdListMap[msg.sender].push(ilanId);
        emit ilanOlusturuldu(hisseId, msg.sender, ilanId, satisFiyat);
    }

    function ilanYayindanKaldir(uint ilanId, uint hisseId) public {
        //sadece owner
        require(adIdMap[ilanId].state == State.ALICI_ICIN_KILITLENDI, "The ad does not removed : state ALICI_ICIN_KILITLENDI");
        adIdMap[ilanId].state = State.YAYINDAN_KALDIRILDI;
        hisseIdAdIdMap[hisseId] = 0;
        uint [] memory msgSenderAds = ownerAdIdListMap[msg.sender];
        for(uint i=0; i< msgSenderAds.length; i++){
            if(msgSenderAds[i] == ilanId){
                delete msgSenderAds[i];
            }
        } 
        emit ilanYayindanKaldirildi(hisseId, msg.sender, ilanId);
    }

    function aliciIcinKilitle(uint ilanId, address aliciAdd, uint fiyat) public {
        //sadece owner
        require(adIdMap[ilanId].state == State.ALICI_ICIN_KILITLENDI, "zaten baska alici icin kitlenmis");
        require(adIdMap[ilanId].state == State.YAYINDAN_KALDIRILDI, "ilan yayinda degil");
        adIdMap[ilanId].state = State.ALICI_ICIN_KILITLENDI;
        adIdMap[ilanId].alici = aliciAdd;
        adIdMap[ilanId].fiyat = fiyat;

        emit aliciIcinKilitlendi(ilanId, msg.sender, aliciAdd);    
    }

    function changeSatisFiyat(uint ilanId, uint newfiyat) public {
        //sadece owner
        require(adIdMap[ilanId].state == State.ALICI_ICIN_KILITLENDI, "The ad does not removed : state ALICI_ICIN_KILITLENDI");
        adIdMap[ilanId].fiyat = newfiyat;
        emit fiyatDegistir(ilanId, newfiyat, msg.sender);
    }

    function getAdIdLUT() public view returns(uint [] memory){
        return adIdLUT;
    } 

}
