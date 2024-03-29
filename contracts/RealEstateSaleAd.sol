// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstateOwnerRelation.sol";
import "./NotaryContractBase.sol";
import "./RealEstate.sol";
import "./HissedarOnay.sol";

contract RealEstateSaleAd is NotaryContractBase{

    RealEstateOwnerRelation realEstateOwnerRelation;
    Owner ownerContract;
    RealEstate realEstate;
    HissedarOnay hissedarOnay;

    event ilanOlusturuldu(uint hisseId, address saticiId, uint ilanId, uint fiyat);
    event hissedarlarinOnayinda(uint hisseId, address saticiId, uint ilanId, uint fiyat);
    event ilanYayindanKaldirildi(address saticiId, uint ilanId);
    event aliciIcinKilitlendi(uint ilanId, address saticiId, address aliciId);    
    event fiyatDegistirildi(uint ilanId, uint yeniSatisFiyat, address saticiId);
    event kilitKaldirildiWithAliciOnayi(uint ilanId);
    event kilitKaldirildiWithSaticiOnayi(uint ilanId);
    event alicisistemHesabinaParaAktardi(address alici, uint ilanId, uint miktar);
    event saticiSistemHesabinaTapuHarciAktardi(address satici, uint ilanId, uint miktar);
    event changedOwnerShip(uint hisseId, address alici, address satici, uint fiyat, uint zaman);
    event mutabakatIslemiRed();
    event mutabakatIslemiOnay();

    mapping (uint => Advertisement) public adIdMap;
    mapping (uint => uint) public hisseIdAdIdMap;
    mapping (address => uint[]) public ownerAdIdListMap;
    mapping (uint => uint) public adIdLUT;
    uint adIdLUTLength = 0;
    uint aliciIcinKitlenenIlanSayisi = 0;
    
    constructor(address ownerContractAdd, address realOwnRelAddress, address realEstateAddress, address hissedarOnayAdd)  {
        ownerContract=Owner(ownerContractAdd);
        realEstateOwnerRelation=RealEstateOwnerRelation(realOwnRelAddress);
        realEstate=RealEstate(realEstateAddress);
        hissedarOnay = HissedarOnay(hissedarOnayAdd);
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
        hissedarVarsaOnayaGonder(ilanId, hisseId, satisFiyat);        
    }

    function hissedarVarsaOnayaGonder(uint ilanId, uint hisseId, uint256 satisFiyat) public {
        
        Hisse memory hisse = realEstateOwnerRelation.getHisse(hisseId);
        RealEstateData memory realEstateData = realEstate.getRealEstateInfo(hisse.realEstateId);
        if(realEstateData.payda != hisse.pay){
            hissedarOnay.onayaGonder(ilanId, hisseId, satisFiyat, msg.sender, realEstateData.payda);
            adIdMap[ilanId].state = State.HISSEDARLARDAN_ONAY_BEKLIYOR;
            emit hissedarlarinOnayinda(hisseId, msg.sender, ilanId, satisFiyat);
        }else{
            emit ilanOlusturuldu(hisseId, msg.sender, ilanId, satisFiyat);
        }        
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
        aliciIcinKitlenenIlanSayisi++;
    }

    function changeSatisFiyat(uint ilanId, uint newfiyat) public {
        Advertisement memory ad =  adIdMap[ilanId];
        require(ad.satici == msg.sender, "Bu islemi sadece satici yapabilir");
        require(ad.state == State.YAYINDA, "Sadece yayinda olan ilanlar icin bu islem yapilabilir");
        require(ad.rayicBedeli <= newfiyat, "Satis fiyat rayic bedelden dusuk olamaz");
        adIdMap[ilanId].fiyat = newfiyat;
        emit fiyatDegistirildi(ilanId, newfiyat, msg.sender);
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
        aliciIcinKitlenenIlanSayisi--;
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

    function teklifFiyatRaicBedeldenDusukMu(uint ilanId, uint fiyat) public view returns(bool){
        return adIdMap[ilanId].rayicBedeli <= fiyat;
    }

    function getIlanSatici(uint ilanId) public view returns(address){
        return adIdMap[ilanId].satici;
    }

    function onayVer(uint onayId, uint ilanId) public {
        hissedarOnay.onayVer(onayId, msg.sender);
        ilanDurumuGuncelle(ilanId);
        emit mutabakatIslemiOnay();
    }

    function reddet(uint onayId, uint ilanId) public {
        hissedarOnay.reddet(onayId, msg.sender);
        ilanDurumuGuncelle(ilanId);
        emit mutabakatIslemiRed();
    }

    function ilanDurumuGuncelle(uint ilanId) public {
        State ilanState = hissedarOnay.ilanYayinlanabilirmi(ilanId);
        adIdMap[ilanId].state = ilanState;
    }

    function alicidanParaAlindi(uint ilanId) public {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        adIdMap[ilanId].aliciParaTransferi = true;
        Advertisement memory advertisement = adIdMap[ilanId];
        if(advertisement.saticiParaTransferi){
            realEstateOwnerRelation.changeOwnerShip(advertisement.hisseId, advertisement.alici, advertisement.satici);
            adIdMap[ilanId].state = State.DEVIR_ISLEMI_TAMAMLANDI;
            aliciIcinKitlenenIlanSayisi--;
            updateLUT(ilanId);
            emit changedOwnerShip(advertisement.hisseId, advertisement.alici, advertisement.satici, advertisement.fiyat, block.timestamp);
        }else{
            emit alicisistemHesabinaParaAktardi(advertisement.alici, ilanId, advertisement.fiyat);
        }
    }

    function saticidanTapuHarciAlindi(uint ilanId) public {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        adIdMap[ilanId].saticiParaTransferi = true;
        Advertisement memory advertisement = adIdMap[ilanId];
        if(advertisement.aliciParaTransferi){
            realEstateOwnerRelation.changeOwnerShip(advertisement.hisseId, advertisement.alici, advertisement.satici);
            adIdMap[ilanId].state = State.DEVIR_ISLEMI_TAMAMLANDI;
            aliciIcinKitlenenIlanSayisi--;
            updateLUT(ilanId);
            emit changedOwnerShip(advertisement.hisseId, advertisement.alici, advertisement.satici, advertisement.fiyat, block.timestamp);
        }else{
            emit saticiSistemHesabinaTapuHarciAktardi(advertisement.alici, ilanId, advertisement.fiyat);
        }
    }

    function getAliciIcinKitlenenIlanlar() public view returns(AdDto[] memory) {
        require(ownerContract.isAdmin(msg.sender), "Bu islemi sadece admin yapabilir");
        AdDto [] memory result = new AdDto[]( aliciIcinKitlenenIlanSayisi);
        uint resultCount = 0;
        for(uint i; i< adIdLUTLength; i++){
            uint ilanId = adIdLUT[i];
            Advertisement memory ad =  adIdMap[ilanId]; 
            if(ad.state == State.ALICI_ICIN_KILITLENDI){
                result[resultCount++] =AdDto(ilanId, ad);
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

    function getHisseAdDataById(uint ilanId) public view returns(HisseAdData memory){
        Advertisement memory ad = adIdMap[ilanId];
        Hisse memory hisse = realEstateOwnerRelation.getHisse(ad.hisseId);
        RealEstateData memory realEstateData = realEstate.getRealEstateInfo(hisse.realEstateId);
        return HisseAdData(ad.hisseId, hisse, ilanId, ad, realEstateData);
    }

    function isAdYayinda(uint ilanId) public view returns(bool){
        Advertisement memory ad = adIdMap[ilanId];
        return ad.state == State.YAYINDA;
    }

}
