// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract NotaryContractBase {
    struct OwnerInfo {
        address  ownerAdd;
        string tcknorVkn;
        string fullName;
        bool registered;      
        Rol rol;
    }

    enum Rol {
        UNAUTHORIZED,
        ADMIN,
        USER
    }
    
    enum PropState {
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
        PropState state;
    }
    
    struct Advertisement{
        uint hisseId;        
        address satici;
        address alici;
        State  state;
        uint256  rayicBedeli;
        uint256  fiyat; //todo double 
        bool  borcuVarMi;
        uint adIdLUTIndex;
        bool aliciParaTransferi;
        bool saticiParaTransferi;
    }

    enum State {
        YAYINDA_DEGIL,
        YAYINDA,
        ALICI_ICIN_KILITLENDI,
        YAYINDAN_KALDIRILDI,
        DEVIR_ISLEMI_TAMAMLANDI,
        ALICI_ONAYI_ILE_KILIT_KALDIRMA
    }

    struct Hisse {
        uint pay;  
       //string edinmeSebebi; //TODO enum
        //uint edinmeZamani;
        uint realEstateId;
        address ownerAdd;
        bool registered;
    }

    struct RealEstateHisse{
        bool registered;
        uint payda;
        uint toplamHisseMiktar;
        uint [] hisseIdList;        
    }

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

    struct HisseAdData {
        uint hisseId;
        Hisse hisse;
        uint ilanId;
        Advertisement ad;
    }

}