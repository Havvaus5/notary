// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstateOwnerRelation.sol";
import "./NotaryContractBase.sol";
import "./RealEstate.sol";

contract HissedarOnay is NotaryContractBase{

    RealEstateOwnerRelation realEstateOwnerRelation;
    RealEstate realEstate;

    event onayEklendi(uint onayId, address ownAdd);

    mapping (uint => OnayData) public onayIdMap;
    mapping (uint => uint[]) public addIdOnayIdListMap;
    mapping (address => uint[]) public ownerOnayIdListMap;
    
    constructor(address realOwnRelAddress, address realEstateAddress)  {        
        realEstateOwnerRelation=RealEstateOwnerRelation(realOwnRelAddress);        
        realEstate=RealEstate(realEstateAddress);
    }

    function onayaGonder(uint realEstateAdId, uint hisseID, uint satisFiyati, address owner, uint realEstatePayda) public {
        Hisse [] memory hisseList = realEstateOwnerRelation.getAllHissedarsByHisseId(hisseID);
        for (uint y = 0; y < hisseList.length; y++) {
            Hisse memory hisse =  hisseList[y];
            if(hisse.ownerAdd != owner){
                uint onayId = uint256(keccak256(abi.encodePacked(block.timestamp, hisse.ownerAdd)));
                uint hisseOran = 100 * hisse.pay / realEstatePayda;
                onayIdMap[onayId] = OnayData(hisse.realEstateId, satisFiyati, hisse.pay, hisseOran, hisse.ownerAdd, realEstateAdId, OnayDurum.BEKLEMEDE);
                ownerOnayIdListMap[hisse.ownerAdd].push(onayId); 
                addIdOnayIdListMap[realEstateAdId].push(onayId);                
            }
        }         
    }


    function getOnaylanacakVeri() public view returns(HisseOnayView[] memory) {
        uint[] memory onayIdList = ownerOnayIdListMap[msg.sender];
        HisseOnayView [] memory result = new HisseOnayView[](onayIdList.length);
        uint resultCount = 0;
        for(uint i = 0; i< onayIdList.length; i++){
            uint onayID = onayIdList[i];
            OnayData memory onayData = onayIdMap[onayID];
            RealEstateData memory realEstateData = realEstate.getRealEstateInfo(onayData.realEstateId);
            if(onayData.onayDurum == OnayDurum.BEKLEMEDE){
                 result[resultCount++] = HisseOnayView(onayID, onayData, realEstateData);
            }
        }
        return result;
    }

    function onayVer(uint onayId, address onayci) public {
        require(onayIdMap[onayId].onayci == onayci, "Bu islemin onaycisi siz degilsiniz");
        onayIdMap[onayId].onayDurum = OnayDurum.KABUL;        
    }

    function reddet(uint onayId, address onayci) public {
        require(onayIdMap[onayId].onayci == onayci, "Bu islemin onaycisi siz degilsiniz");
        onayIdMap[onayId].onayDurum = OnayDurum.RED;        
    }

    function ilanYayinlanabilirmi(uint realEstateAdId) public view returns(State){
        uint[] memory onayIdList  = addIdOnayIdListMap[realEstateAdId];
        uint onayVerenSayisi = 0;
        uint reddedenSayisi = 0;
        for (uint y = 0; y < onayIdList.length; y++) {
            OnayData memory onayData = onayIdMap[onayIdList[y]];
            if(onayData.onayDurum == OnayDurum.KABUL){
                onayVerenSayisi+=onayData.hisseOran;
            }else if(onayData.onayDurum == OnayDurum.RED){
                reddedenSayisi+= onayData.hisseOran;
            }else if(onayData.onayDurum == OnayDurum.BEKLEMEDE){
                return State.HISSEDARLARDAN_ONAY_BEKLIYOR;
            }
        }   
        return onayVerenSayisi > reddedenSayisi ? State.YAYINDA : State.HISSEDARLAR_ARASINDA_MUTABAKAT_SAGLANAMADI;
    }


}
