// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstateOwnerRelation.sol";
import "./NotaryContractBase.sol";
import "./RealEstate.sol";

contract RealEstateSaleAd is NotaryContractBase{

    RealEstateOwnerRelation realEstateOwnerRelation;
    Owner ownerContract;
    RealEstate realEstate;

    event ilanOlusturuldu(uint hisseId, address saticiId, uint ilanId, uint fiyat);
    event ilanYayindanKaldirildi(address saticiId, uint ilanId);
    event aliciIcinKilitlendi(uint ilanId, address saticiId, address aliciId);    
    event fiyatDegistir(uint ilanId, uint yeniSatisFiyat, address saticiId);
    event kilitKaldirildiWithAliciOnayi(uint ilanId);
    event kilitKaldirildiWithSaticiOnayi(uint ilanId);
    event alicisistemHesabinaParaAktardi(address alici, uint ilanId, uint miktar);
 
    mapping (uint => Advertisement) public adIdMap;
    mapping (uint => uint) public hisseIdAdIdMap;
    mapping (address => uint[]) public ownerAdIdListMap;
    mapping (uint => uint) public adIdLUT;
    uint adIdLUTLength = 0;

    constructor(address ownerContractAdd, address realOwnRelAddress, address realEstateAddress)  {
        ownerContract=Owner(ownerContractAdd);
        realEstateOwnerRelation=RealEstateOwnerRelation(realOwnRelAddress);
        realEstate=RealEstate(realEstateAddress);
    }

    function ilanOlustur(uint hisseId, uint256 rayicBedeli, uint256 satisFiyat, bool borcuVarMi) public {
        require(realEstateOwnerRelation.hisseSatisaCikabilirMi(hisseId, msg.sender), "Hisse sadece sahibi tarafindan ilan olusturulmali");
        require(hisseIdAdIdMap[hisseId] == 0, "advertisement for real estate already exist in the system");
        require(rayicBedeli <= satisFiyat, "Satis fiyat rayic bedelden dusuk olamaz");
        require(!borcuVarMi, "Gayrimenkulun vergi borcu olmaz");

        uint ilanId = block.timestamp;
        Advertisement memory ad = Advertisement(hisseId, msg.sender, address(0), State.YAYINDA, rayicBedeli, satisFiyat, borcuVarMi, adIdLUTLength, false, false);
        adIdMap[ilanId] = ad;
        hisseIdAdIdMap[hisseId] = ilanId;
        adIdLUT[adIdLUTLength] = ilanId;
        adIdLUTLength++;
        ownerAdIdListMap[msg.sender].push(ilanId);
        emit ilanOlusturuldu(hisseId, msg.sender, ilanId, satisFiyat);
    }

    function ilanYayindanKaldir(uint ilanId) public {
        require(adIdMap[ilanId].satici == msg.sender, "Bu islem sadece satici tarafindan yapilir");
        require(adIdMap[ilanId].state == State.YAYINDA, "Sadece yayinda olan ilanlar icin bu islem yapilabilir");
        adIdMap[ilanId].state = State.YAYINDAN_KALDIRILDI;        
        updateLUT(ilanId);
        emit ilanYayindanKaldirildi(msg.sender, ilanId);
    }
    
    function updateLUT(uint ilanId) private {
        Advertisement memory yayindanKaldirildiAd = adIdMap[ilanId];
        hisseIdAdIdMap[yayindanKaldirildiAd.hisseId] = 0;
        uint yayindanKaldirilanItemIndex = yayindanKaldirildiAd.adIdLUTIndex;
        uint lastAdInLUT = adIdLUT[adIdLUTLength -1];
        if(ilanId != lastAdInLUT){
            adIdMap[lastAdInLUT].adIdLUTIndex = yayindanKaldirilanItemIndex;
            adIdLUT[yayindanKaldirilanItemIndex] = lastAdInLUT;              
        }
        adIdLUTLength--;
    }

    function aliciIcinKilitle(uint ilanId, address aliciAdd, uint fiyat) public {
        Advertisement memory ad =  adIdMap[ilanId];
        //require(ad.satici == msg.sender, "Bu islemi sadece satici yapabilir");
        require(ad.state == State.YAYINDA, "Sadece yayinda olan ilanlar icin bu islem yapilabilir");
        require(ad.rayicBedeli <= fiyat, "Satis fiyat rayic bedelden dusuk olamaz");
        adIdMap[ilanId].state = State.ALICI_ICIN_KILITLENDI;
        adIdMap[ilanId].alici = aliciAdd;
        adIdMap[ilanId].fiyat = fiyat;

        emit aliciIcinKilitlendi(ilanId, msg.sender, aliciAdd);    
    }

    function changeSatisFiyat(uint ilanId, uint newfiyat) public {
        Advertisement memory ad =  adIdMap[ilanId];
        require(ad.satici == msg.sender, "Bu islemi sadece satici yapabilir");
        require(ad.state == State.YAYINDA, "Sadece yayinda olan ilanlar icin bu islem yapilabilir");
        require(ad.rayicBedeli <= newfiyat, "Satis fiyat rayic bedelden dusuk olamaz");
        adIdMap[ilanId].fiyat = newfiyat;
        emit fiyatDegistir(ilanId, newfiyat, msg.sender);
    }

    function kilitKaldirWithAliciOnayi(uint ilanId) public {
        require(msg.sender == adIdMap[ilanId].alici, "Bu islem sadece alici tarafindan yapilir");
        require(adIdMap[ilanId].state == State.ALICI_ICIN_KILITLENDI, "ilan alici icin kitlenmemis");
        adIdMap[ilanId].state = State.ALICI_ONAYI_ILE_KILIT_KALDIRMA;
        emit kilitKaldirildiWithAliciOnayi(ilanId);
    }

    function kilitKaldirWithSaticiOnayi(uint ilanId) public {
        require(msg.sender == adIdMap[ilanId].satici, "Bu islem sadece satici tarafindan yapilir");
        require(adIdMap[ilanId].state == State.ALICI_ONAYI_ILE_KILIT_KALDIRMA, "oncelikle alici kilit kaldirmali");
        adIdMap[ilanId].state = State.YAYINDA;
        emit kilitKaldirildiWithSaticiOnayi(ilanId);
    }

    function getUserAds(address ownAdd) public view returns(Advertisement [] memory){
        //sadece kullanici yapabilsin kendi ilanlarini görebilsin
        uint[] memory ownAdIds = ownerAdIdListMap[ownAdd];
        Advertisement [] memory ads = new Advertisement[](ownAdIds.length);        
        for(uint i = 0; i< ownAdIds.length; i++){
            Advertisement memory ad = adIdMap[ownAdIds[i]];
            if(ad.state != State.YAYINDAN_KALDIRILDI || ad.state != State.DEVIR_ISLEMI_TAMAMLANDI){
                ads[i] = adIdMap[ownAdIds[i]];
            }
        }
        return ads;
    }   

    function ilanaTeklifVerilebilirMi(uint ilanId) public view returns(bool){
        return adIdMap[ilanId].state == State.YAYINDA;
    }

    function getIlanSatici(uint ilanId) public view returns(address){
        return adIdMap[ilanId].satici;
    }

    function alicidanParaAlindi(uint ilanId) public {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        adIdMap[ilanId].aliciParaTransferi = true;
        Advertisement memory advertisement = adIdMap[ilanId];
        if(advertisement.saticiParaTransferi){
            realEstateOwnerRelation.changeOwnerShip(advertisement.hisseId, advertisement.alici);
            adIdMap[ilanId].state = State.DEVIR_ISLEMI_TAMAMLANDI;
            updateLUT(ilanId);
        }
    }

    function saticidanTapuHarciAlindi(uint ilanId) public {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        adIdMap[ilanId].saticiParaTransferi = true;
        Advertisement memory advertisement = adIdMap[ilanId];
        if(advertisement.aliciParaTransferi){
            realEstateOwnerRelation.changeOwnerShip(advertisement.hisseId, advertisement.alici);
            adIdMap[ilanId].state = State.DEVIR_ISLEMI_TAMAMLANDI;
            updateLUT(ilanId);
        }
    }

    function getAliciIcinKitlenenIlanlar() public view returns(AdDto[] memory) {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        AdDto [] memory result = new AdDto[]( adIdLUTLength);
        uint resultCount = 0;
        for(uint i; i< adIdLUTLength; i++){
            uint ilanId =adIdLUT[i];
            Advertisement memory ad =  adIdMap[ilanId]; 
            if(ad.state == State.ALICI_ICIN_KILITLENDI){
                result[resultCount] =AdDto(ilanId, ad);
            }
        }
        return result;
    }

    function getUserAssets(address ownAdd) public view returns(HisseAdData[] memory){
        uint hisseIdsLength = realEstateOwnerRelation.getOwnerHisseLength(ownAdd);
        HisseAdData [] memory result = new HisseAdData[](hisseIdsLength);
        uint resultCount = 0;
        for(uint i = 0; i< hisseIdsLength; i++){
            uint hisseId = realEstateOwnerRelation.getOwnerHisseId(ownAdd, i);
           if(hisseId != 0 ){
                Hisse memory hisse = realEstateOwnerRelation.getHisse(hisseId);
                RealEstateData memory realEstateData = realEstate.getRealEstateInfo(hisse.realEstateId);
                uint ilanId = hisseIdAdIdMap[hisseId];
                Advertisement memory advertisement = adIdMap[ilanId];
                result[resultCount++] = HisseAdData(hisseId, hisse, ilanId, advertisement, realEstateData);

            }
        }
        return result;
    }

    function getAllAds() public view returns(HisseAdData [] memory){
        HisseAdData [] memory result = new HisseAdData[](adIdLUTLength);
        for(uint i = 0; i< adIdLUTLength; i++){
            uint ilanId = adIdLUT[i];
            Advertisement memory ad = adIdMap[ilanId];
            Hisse memory hisse = realEstateOwnerRelation.getHisse(ad.hisseId);
            RealEstateData memory realEstateData = realEstate.getRealEstateInfo(hisse.realEstateId);
            result[i] = HisseAdData(ad.hisseId, hisse, ilanId, ad, realEstateData);
        }
        return result;
    }

    function getHisseAdDataById(uint ilanId) public view returns (HisseAdData memory){
            Advertisement memory ad = adIdMap[ilanId];
            Hisse memory hisse = realEstateOwnerRelation.getHisse(ad.hisseId);
            RealEstateData memory realEstateData = realEstate.getRealEstateInfo(hisse.realEstateId);
            return HisseAdData(ad.hisseId, hisse, ilanId, ad, realEstateData);
    }

}
