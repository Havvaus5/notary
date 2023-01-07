// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Owner.sol";
import "./RealEstateSaleAd.sol";

contract Proposition {

    RealEstateSaleAd realEstateSaleAdContract;
    Owner ownerContract;

    enum State {
        EMPTY,
        KABUL,
        RED,
        BEKLEMEDE
    }

    struct PropositionData {
        address alici;
        address satici;
        uint fiyat;
        uint ilanId;
        State state;
    }

    mapping(uint => PropositionData) public propIdDataMap;
    mapping(address => uint []) gonderilenTeklifler;
    mapping(address => uint []) alinanTeklifler;
    mapping(uint => uint[]) ilanIdTeklifIdListMap;

    event teklifGonderildi(uint teklifId, uint ilanId, address saticiAdd, address aliciAdd, uint fiyat);
    event teklifReddedildi(uint teklifId);
    event teklifKabulEdildi(uint teklifId);

    constructor(address realEstateSaleAdContractAdd)  {
        //ownerContract=Owner(ownerContractAdd);
        realEstateSaleAdContract=RealEstateSaleAd(realEstateSaleAdContractAdd);
    }

    function teklifGonder(uint ilanId, uint fiyat) public {
        address satici = realEstateSaleAdContract.getIlanSatici(ilanId);
        require(satici != msg.sender, "Bu ilanin saticisi sizsniz teklif veremezsiniz");
        require(realEstateSaleAdContract.ilanaTeklifVerilebilirMi(ilanId), "Bu ilana teklif verilemez");
        uint propId = block.timestamp;        
        address alici = msg.sender;
        propIdDataMap[propId] = PropositionData(alici, satici, fiyat, ilanId, State.BEKLEMEDE);
        gonderilenTeklifler[alici].push(propId);
        alinanTeklifler[satici].push(propId);
        ilanIdTeklifIdListMap[ilanId].push(propId);
        emit teklifGonderildi(propId, ilanId, satici, alici, fiyat);
    }

    function teklifReddet(uint propId) public {
        require(propIdDataMap[propId].satici == msg.sender, "Bu teklif sacede satici tarafindan reddedilir");
        require(propIdDataMap[propId].state == State.BEKLEMEDE,  "Sadece beklemede olan teklifler reddedilir");
        propIdDataMap[propId].state = State.RED;
        emit teklifReddedildi(propId);        
        
    }

    function teklifKabulEt(uint propId) public {
        require(propIdDataMap[propId].satici == msg.sender, "Bu teklif sacede satici tarafindan kabul edilir");
        require(propIdDataMap[propId].state == State.BEKLEMEDE, "Sadece beklemede olan teklifler kabul edilir");
        PropositionData memory prop = propIdDataMap[propId];
        realEstateSaleAdContract.aliciIcinKilitle(prop.ilanId, prop.alici, prop.fiyat);
        propIdDataMap[propId].state = State.KABUL;
        denyOtherProps(prop.ilanId, propId);
        emit teklifKabulEdildi(propId);
        

    }

    function denyOtherProps(uint ilanId, uint acceptedPropId) private {
        uint propSizeForAd = ilanIdTeklifIdListMap[ilanId].length;
        for(uint i = 0; i< propSizeForAd; i++){
            uint propId = ilanIdTeklifIdListMap[ilanId][i];
            if( propId != acceptedPropId){
                propIdDataMap[propId].state = State.RED;    
            }
        }
    }

    function getGonderilenTeklifler(address aliciAdd) public view returns (PropositionData [] memory){
        uint propSizeOfAlici = gonderilenTeklifler[aliciAdd].length;
        PropositionData [] memory props = new PropositionData[](propSizeOfAlici);
        for(uint i = 0; i< propSizeOfAlici; i++){
            props[i] = propIdDataMap[gonderilenTeklifler[aliciAdd][i]]; 
        } 
        return props;
    }



}