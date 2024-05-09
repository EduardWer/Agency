// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RealEstateAgency {
    enum EstateType { Apartment, House, Land }
    enum AdStatus { Open, Closed }

    struct Estate {
        uint id;
        address owner;
        EstateType estateType;
        bool isActive;
    }

    struct Ad {
        uint id;
        uint estateId;
        address owner;
        uint price;
        AdStatus status;
    }

    mapping(uint => Estate) public estates;
    mapping(uint => Ad) public ads;

    uint public estateCount;
    uint public adCount;

    uint public pendingWithdrawal;

    address public owner;

    event EstateCreated(address owner, uint estateId, uint timestamp, EstateType estateType);
    event AdCreated(address owner, uint estateId, uint adId, uint timestamp, uint price);
    event EstateUpdated(address owner, uint estateId, uint timestamp, bool isActive);
    event AdUpdated(address owner, uint estateId, uint adId, uint timestamp, AdStatus status);
    event EstatePurchased(address owner, address buyer, uint adId, uint estateId, AdStatus adStatus, uint timestamp, uint price);
    event FundsSent(address receiver, uint amount, uint timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    function createEstate(EstateType estateType) public { //Функция createEstate: создает новую недвижимость с указанным типом и устанавливает владельца как вызывающий адрес. Генерирует событие EstateCreated.
        estates[estateCount] = Estate(estateCount, msg.sender, estateType, true);
        emit EstateCreated(msg.sender, estateCount, block.timestamp, estateType);
        estateCount++;
    }

    function createAd(uint estateId, uint price) public {// Функция createAd: создает новое объявление для определенной недвижимости с указанной ценой. Проверяет, что вызывающий адрес является владельцем недвижимости и что недвижимость активна. Генерирует событие AdCreated.
        require(estates[estateId].owner == msg.sender, "Only the estate owner can create an ad.");
        require(estates[estateId].isActive, "The estate must be active to create an ad.");
        ads[adCount] = Ad(adCount, estateId, msg.sender, price, AdStatus.Open);
        emit AdCreated(msg.sender, estateId, adCount, block.timestamp, price);
        adCount++;
    }

    function updateEstateStatus(uint estateId) public { //обновляет статус недвижимости (активный/неактивный) для указанной недвижимости.
        require(estates[estateId].owner == msg.sender, "Only the estate owner can update the status.");
        estates[estateId].isActive = !estates[estateId].isActive;
        emit EstateUpdated(msg.sender, estateId, block.timestamp, estates[estateId].isActive);

        if (!estates[estateId].isActive) {
            for (uint i = 0; i < adCount; i++) {
                if (ads[i].estateId == estateId && ads[i].status == AdStatus.Open) {
                    ads[i].status = AdStatus.Closed;
                    emit AdUpdated(msg.sender, estateId, i, block.timestamp, AdStatus.Closed);
                }
            }
        }
    }

    function updateAdStatus(uint adId, AdStatus status) public { //обновляет статус объявления (открытый/закрытый) для указанного объявления.
        require(ads[adId].owner == msg.sender, "Only the ad owner can update the status.");
        require(estates[ads[adId].estateId].isActive, "The estate must be active to update the ad status.");
        ads[adId].status = status;
        emit AdUpdated(msg.sender, ads[adId].estateId, adId, block.timestamp, status);
    }

    function purchaseEstate(uint adId) public payable { //позволяет покупателю приобрести недвижимость, отправив средства на смарт-контракт
        require(ads[adId].status == AdStatus.Open, "The ad must be open to purchase the estate.");
        require(msg.value >= ads[adId].price, "Insufficient funds to purchase the estate.");

        pendingWithdrawal += msg.value;
        ads[adId].status = AdStatus.Closed;

        emit EstatePurchased(
            ads[adId].owner,
            msg.sender,
            adId,
            ads[adId].estateId,

            AdStatus.Closed,
            block.timestamp,
            ads[adId].price
        );
    }

    function withdrawFunds(uint amount) public onlyOwner { //позволяет владельцу контракта снимать средства со смарт-контракта.
        require(amount <= pendingWithdrawal, "Insufficient funds in the contract.");
        pendingWithdrawal -= amount;
        payable(msg.sender).transfer(amount);
        emit FundsSent(msg.sender, amount, block.timestamp);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getAllEstates() public view returns (Estate[] memory) {  //возвращает массив всех существующих объектов недвижимости.
        Estate[] memory result = new Estate[](estateCount);
        uint counter = 0;
        for (uint i = 0; i < estateCount; i++) {
            if (estates[i].id != 0) {
                result[counter] = estates[i];
                counter++;
            }
        }
        return result;
    }

    function getAllAds() public view returns (Ad[] memory) { //возвращает массив всех существующих объявлений.
        Ad[] memory result = new Ad[](adCount);
        uint counter = 0;
        for (uint i = 0; i < adCount; i++) {
            if (ads[i].id != 0) {
                result[counter] = ads[i];
                counter++;
            }
        }
        return result;
    }
}
