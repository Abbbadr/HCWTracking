// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// Access control contract
contract AccessControl {
  /*** EVENTS ***/

  // Emit when contract ownership changes.
  event ownershipTransferred(address from, address to);

  /*** MODIFIERS ***/

  // Functions with modifier can only be called by _owner.
  modifier onlyOwner {
    require(msg.sender == _owner);
    _;
  }

  /*** STORAGE ***/

  // Store address of contract owner.
  address private _owner;

  // Set _owner to transaction sender on contract deployment.
  constructor() {
    _owner = msg.sender;
    emit ownershipTransferred(address(0), _owner);
  }
  
  // Transfer ownership of contract to Address of new owner. 
  function transferOwnership(address to) public onlyOwner {
    require(to != address(0), "rejected: cannot transfer to zero address");
    emit ownershipTransferred(_owner, to);
    _owner = to;
  }
}

// Treatment contract for HCW supply chain management
contract Treatment is AccessControl {
  /*** EVENTS ***/

  // Emit when each new stakeholder is created.
  event treatmentFacilityCreated(address facilityAddress, string facilityName, string facilityId);

  event disinfectionUnitCreated(address unitAddress, string unitName, string unitId, string operatorName, string operatorId);

  event landfillOperatorCreated(address landfillAddress, string landfillName, string operatorName, string operatorId);

  // Emit when disinfection is requested.
  event disinfectionRequested(string facilityId, string wasteId, uint64 wasteWeight, WasteType[] wasteTypes, string wasteImage);

  // Emit when disinfection is accepted.
  event disinfectionAccepted(string unitId, string wasteId, uint64 wasteWeight, WasteType[] wasteTypes);

  // Emit when landfilling is requested.
  event landfillingRequested(string unitId,uint64 ashWeight);

  // Emit when landfilling is accepted.
  event landfillingAccepted(string operatorId, uint64 ashWeight, uint256 landfillingDate);

  // Emit when ash shipment confirmed.
  event ashShipmentConfirmed( string operatorId, string landfillImage);

  /*** MODIFIERS ***/

  // Functions with modifier can only be called when sender's address is paired with stakeholder Id.
  
  modifier onlyFacility(string memory facilityId) {
    require(_facilityIdToAddress[facilityId] == msg.sender);
    _;
  }

  modifier onlyDisinfection(string memory unitId) {
    require(_unitIdToAddress[unitId] == msg.sender);
    _;
  }

  modifier onlyLandfill(string memory operatorId) {
    require(_operatorIdToAddress[operatorId] == msg.sender);
    _;
  }

  /*** DATA STRUCTURES ***/

  // Enum of all waste types.
  enum WasteType {
    None,         /// 0
    Infectious,   /// 1
    Hazardous,    /// 2
    Radioactive,  /// 3
    General       /// 4
  }

  // Stores all data for each stakeholder.
  
  struct TreatmentFacility {address facilityAddress; string facilityName; string facilityId; string wasteId; uint64 wasteWeight; 
  WasteType wasteType; string wasteImage; uint256 requestDate;}

  // Stores all data for disinfection units.
  struct DisinfectionUnit {address unitAddress; string unitName; string unitId; string operatorName; string operatorId; string wasteId;
    uint64 wasteWeight; uint64 ashWeight; uint256 disinfectionDate;}

  // Stores all data for landfill operator.
  struct LandfillOperator {address landfillAddress; string landfillName; string operatorName; string operatorId; string landfillImage; uint256 landfillingDate;}

  /*** STORAGE ***/

  mapping(string => TreatmentFacility) public facilityIdToTreatmentFacility;
  mapping(string => address) private _facilityIdToAddress;
  mapping(string => WasteType[]) private _facilityIdToWasteTypes;
  mapping(string => DisinfectionUnit) public unitIdToDisinfectionUnit;
  mapping(string => address) private _unitIdToAddress;
  mapping(string => LandfillOperator) public operatorIdToLandfillOperator;
  mapping(string => address) private _operatorIdToAddress;
  mapping(string => bool) public wasteToBeDisinfected;
  mapping(string => bool) public wasteToBeLandfilled;

  // Create new stakeholder and create event.

  function addTreatmentFacility(address facilityAddress, string memory facilityName, string memory facilityId) public onlyOwner {
    TreatmentFacility memory newTreatmentFacility;
    newTreatmentFacility.facilityAddress = facilityAddress;
    newTreatmentFacility.facilityName = facilityName;
    newTreatmentFacility.facilityId = facilityId;

    facilityIdToTreatmentFacility[facilityId] = newTreatmentFacility;
    _facilityIdToAddress[facilityId] = facilityAddress;
    emit treatmentFacilityCreated(facilityAddress, facilityName, facilityId);
  }

  function addDisinfectionUnit(address unitAddress, string memory unitName, string memory unitId, string memory operatorName, string memory operatorId) public onlyOwner {
    DisinfectionUnit memory newDisinfectionUnit;
    newDisinfectionUnit.unitAddress = unitAddress;
    newDisinfectionUnit.unitName = unitName;
    newDisinfectionUnit.unitId = unitId;
    newDisinfectionUnit.operatorName = operatorName;
    newDisinfectionUnit.operatorId = operatorId;

    unitIdToDisinfectionUnit[unitId] = newDisinfectionUnit;
    _unitIdToAddress[unitId] = unitAddress;
    emit disinfectionUnitCreated(unitAddress, unitName, unitId, operatorName, operatorId);
  }

  function addLandfillOperator(address landfillAddress, string memory landfillName, string memory operatorName, string memory operatorId) public onlyOwner {
    LandfillOperator memory newLandfillOperator;
    newLandfillOperator.landfillAddress = landfillAddress;
    newLandfillOperator.landfillName = landfillName;
    newLandfillOperator.operatorName = operatorName;
    newLandfillOperator.operatorId = operatorId;

    operatorIdToLandfillOperator[operatorId] = newLandfillOperator;
    _operatorIdToAddress[operatorId] = landfillAddress;
    emit landfillOperatorCreated(landfillAddress, landfillName, operatorName, operatorId);
  }

  function requestDisinfection(string memory facilityId, string memory wasteId, uint64 wasteWeight, WasteType[] memory wasteTypes, string memory wasteImage
  ) public onlyFacility(facilityId) {
    TreatmentFacility memory treatmentFacility = facilityIdToTreatmentFacility[facilityId];
    treatmentFacility.wasteId = wasteId;
    treatmentFacility.wasteWeight = wasteWeight;
    treatmentFacility.wasteImage = wasteImage;
    treatmentFacility.requestDate = block.timestamp;
    _facilityIdToWasteTypes[facilityId] = wasteTypes;

    facilityIdToTreatmentFacility[facilityId] = treatmentFacility;
    wasteToBeDisinfected[facilityId] = true;

    emit disinfectionRequested(facilityId, wasteId, wasteWeight, wasteTypes, wasteImage);
  }

  function acceptDisinfection(string memory facilityId, string memory unitId) public onlyDisinfection(unitId) {
    TreatmentFacility memory treatmentFacility = facilityIdToTreatmentFacility[facilityId];
    string memory wasteId = treatmentFacility.wasteId;
    uint64 wasteWeight = treatmentFacility.wasteWeight;
    WasteType[] memory wasteTypes = _facilityIdToWasteTypes[facilityId];

    facilityIdToTreatmentFacility[facilityId].wasteId = "";
    facilityIdToTreatmentFacility[facilityId].wasteWeight = 0;
    facilityIdToTreatmentFacility[facilityId].requestDate = 0;
    delete _facilityIdToWasteTypes[facilityId];
    wasteToBeDisinfected[facilityId] = false;

    DisinfectionUnit memory disinfectionUnit = unitIdToDisinfectionUnit[unitId];
    disinfectionUnit.wasteId = wasteId;
    disinfectionUnit.wasteWeight = wasteWeight;

    unitIdToDisinfectionUnit[unitId] = disinfectionUnit;

    emit disinfectionAccepted(unitId, wasteId, wasteWeight, wasteTypes);
  }

  function reportAsh(string memory unitId, uint64 ashWeight) public onlyDisinfection(unitId) {
    unitIdToDisinfectionUnit[unitId].ashWeight = ashWeight;
  }

  function requestLandfilling(string memory unitId) public onlyDisinfection(unitId) {
    wasteToBeLandfilled[unitId] = true;

    uint64 ashWeight = unitIdToDisinfectionUnit[unitId].ashWeight;

    emit landfillingRequested(unitId, ashWeight);
  }

  function acceptLandfilling(string memory unitId, string memory operatorId) public onlyLandfill(operatorId) {
    uint64 ashWeight = unitIdToDisinfectionUnit[unitId].ashWeight;

    unitIdToDisinfectionUnit[unitId].wasteId = "";
    unitIdToDisinfectionUnit[unitId].wasteWeight = 0;
    unitIdToDisinfectionUnit[unitId].ashWeight = 0;
    wasteToBeLandfilled[unitId] = false;

    operatorIdToLandfillOperator[operatorId].landfillingDate = block.timestamp;

    emit landfillingAccepted(operatorId, ashWeight, block.timestamp);
  }

  function confirmAshShipment(string memory operatorId, string memory landfillImage) public onlyLandfill(operatorId) {
    operatorIdToLandfillOperator[operatorId].landfillImage = landfillImage;
    emit ashShipmentConfirmed(operatorId, landfillImage);
  }
}