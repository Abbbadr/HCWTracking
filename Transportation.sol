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

// Transportation contract for HCW supply chain management
contract Transportation is AccessControl {
  /*** EVENTS ***/

  // Emit when each new stakeholder is created.
  event wasteManagementOfficerCreated(address officerAddress, string officerName, string officerId, string hospitalName, string hospitalId);

  event wasteCollectorCreated(address vehicleAddress, string vehicleVIN, string driverName, string driverId);

  event treatmentFacilityCreated(address facilityAddress, string facilityName, string facilityId);

  // Emit when deposit receieved.
  event depositReceived(address senderAddress, string senderName, string senderId, uint256 senderAmount, uint256 senderTime);

  // Emit when transportation requested.
  event transportationRequested(string officerId, string wasteId, uint64 wasteWeight, WasteType[] wasteTypes, uint256 transportationRequestDate);

  // Emit when transportation accepted.
  event transportationAccepted( string driverId, string wasteId, uint64 wasteWeight, WasteType[] wasteTypes, uint256 arrivalDate);

  // Emit when treatment requested.
  event treatmentRequested(string driverId, string wasteId, uint64 wasteWeight, WasteType[] wasteTypes);

  // Emit when treatment accepted.
  event treatmentAccepted(string facilityId, string wasteId, uint64 wasteWeight, WasteType[] wasteTypes, uint256 arrivalDate);

  // Emit when fine issued.
  event fineIssued(address fineRecipientAddress, string fineRecipientId, string fineRecipientName, uint256 fineAmount);

  // Emit when deposit is returned.
  event depositReturned(address depositRecipientAddress, string depositRecipientId, string depositRecipientName);

  // Emit when shipment data is to be shared.
  event shipmentData( string wasteId, uint64 wasteWeight, WasteType[] wasteTypes, string wasteImage);

  // Emit when shipment is confirmed.
  event shipmentConfirmed(string wasteId, uint64 wasteWeight, WasteType[] wasteTypes, string wasteImage, uint256 shipmentDate);

  /*** MODIFIERS ***/

 // Functions with modifier can only be called when sender's address is paired with stakeholder Id.
 
  modifier onlyOfficer(string memory officerId) {
    require(_officerIdToAddress[officerId] == msg.sender);
    _;
  }

  modifier onlyDriver(string memory driverId) {
    require(_driverIdToAddress[driverId] == msg.sender);
    _;
  }

  modifier onlyFacility(string memory facilityId) {
    require(_facilityIdToAddress[facilityId] == msg.sender);
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

  // Stores all data for each stakholder.
  
  struct WasteManagementOfficer {address officerAddress; string officerName; string officerId; string hospitalName; string hospitalId; string storageStaffName; 
    string storageStaffId; string wasteId; uint64 wasteWeight;  WasteType[] wasteTypes; string[] wasteImages; uint256 transportationRequestDate;}

  struct WasteCollector {address vehicleAddress; string vehicleVIN; string driverName; string driverId; string wasteId; uint64 wasteWeight; WasteType[] wasteTypes;}

  struct TreatmentFacility {address facilityAddress; string facilityName; string facilityId; string wasteId; uint64 wasteWeight; WasteType wasteType;
    string wasteImage; uint256 arrivalDate;}

  /*** STORAGE ***/

  mapping(string => WasteManagementOfficer) officerIdToWasteManagementOfficer;
  mapping(string => address) private _officerIdToAddress;
  mapping(string => WasteType[]) private _officerIdToWasteTypes;
  mapping(string => WasteCollector) driverIdToWasteCollector;
  mapping(string => address payable) private _driverIdToAddress;
  mapping(string => WasteType[]) private _driverIdToWasteTypes;
  mapping(string => TreatmentFacility) facilityIdToTreatmentFacility;
  mapping(string => address payable) private _facilityIdToAddress;
  mapping(string => WasteType[]) private _facilityIdToWasteTypes;
  mapping(string => uint256) collectorDeposits;
  mapping(string => uint256) facilityDeposits;
  mapping(string => bool) wasteToBeTransported;
  mapping(string => bool) wasteToBeTreated;

  // Create new stakeholder and create event.

  function addWasteManagementOfficer(address officerAddress, string memory officerName, string memory officerId, string memory hospitalName, string memory hospitalId, 
    string memory storageStaffName, string memory storageStaffId) public onlyOwner {
    WasteManagementOfficer memory newWasteManagementOfficer;
    newWasteManagementOfficer.officerAddress = officerAddress;
    newWasteManagementOfficer.officerName = officerName;
    newWasteManagementOfficer.officerId = officerId;
    newWasteManagementOfficer.hospitalName = hospitalName;
    newWasteManagementOfficer.hospitalId = hospitalId;
    newWasteManagementOfficer.storageStaffName = storageStaffName;
    newWasteManagementOfficer.storageStaffId = storageStaffId;

    officerIdToWasteManagementOfficer[officerId] = newWasteManagementOfficer;
    _officerIdToAddress[officerId] = officerAddress;
    emit wasteManagementOfficerCreated(officerAddress, officerName, officerId, hospitalName, hospitalId);
  }

  function addWasteCollector(address payable vehicleAddress, string memory vehicleVIN, string memory driverName, string memory driverId) public onlyOwner {
    WasteCollector memory newWasteCollector;
    newWasteCollector.vehicleAddress = vehicleAddress;
    newWasteCollector.vehicleVIN = vehicleVIN;
    newWasteCollector.driverName = driverName;
    newWasteCollector.driverId = driverId;

    driverIdToWasteCollector[driverId] = newWasteCollector;
    _driverIdToAddress[driverId] = vehicleAddress;
    emit wasteCollectorCreated(vehicleAddress, vehicleVIN, driverName, driverId);
  }

  function addTreatmentFacility(address payable facilityAddress, string memory facilityName, string memory facilityId) public onlyOwner {
    TreatmentFacility memory newTreatmentFacility;
    newTreatmentFacility.facilityAddress = facilityAddress;
    newTreatmentFacility.facilityName = facilityName;
    newTreatmentFacility.facilityId = facilityId;

    facilityIdToTreatmentFacility[facilityId] = newTreatmentFacility;
    _facilityIdToAddress[facilityId] = facilityAddress;
    emit treatmentFacilityCreated(facilityAddress, facilityName, facilityId);
  }

  function collectorDeposit(string memory driverId) public payable onlyDriver(driverId) {
    require(collectorDeposits[driverId] == 0);
    /// 0.1 ETH
    require(msg.value >= 1000000000000000000 wei, "rejected: sufficient deposit amount not received");

    collectorDeposits[driverId] = uint256(msg.value);
    emit depositReceived(msg.sender, "Waste Collector", driverId, msg.value, block.timestamp);
  }

  function facilityDeposit(string memory facilityId) public payable onlyFacility(facilityId) {
    require(facilityDeposits[facilityId] == 0);
    /// 0.1 ETH
    require(msg.value >= 1000000000000000000 wei, "rejected: sufficient deposit amount not received");

    facilityDeposits[facilityId] = uint256(msg.value);
    emit depositReceived(msg.sender, "Treatment Facility", facilityId, msg.value, block.timestamp);
  }

  function requestOffsiteTransportation(string memory officerId, string memory wasteId, uint64 wasteWeight, WasteType[] memory wasteTypes) public onlyOfficer(officerId) {
    WasteManagementOfficer memory wasteManagementOfficer = officerIdToWasteManagementOfficer[officerId];
    wasteManagementOfficer.wasteId = wasteId;
    wasteManagementOfficer.wasteWeight = wasteWeight;
    wasteManagementOfficer.transportationRequestDate = block.timestamp;
    _officerIdToWasteTypes[officerId] = wasteTypes;

    officerIdToWasteManagementOfficer[officerId] = wasteManagementOfficer;
    wasteToBeTransported[officerId] = true;

    emit transportationRequested(officerId, wasteId, wasteWeight, wasteTypes, block.timestamp); 
  }

  function acceptOffsiteTransportation(string memory driverId, string memory officerId) public onlyDriver(driverId) {
    WasteManagementOfficer memory wasteManagementOfficer = officerIdToWasteManagementOfficer[officerId];
    string memory wasteId = wasteManagementOfficer.wasteId;
    uint64 wasteWeight = wasteManagementOfficer.wasteWeight;
    WasteType[] memory wasteTypes = _officerIdToWasteTypes[officerId];

    officerIdToWasteManagementOfficer[officerId].wasteId = "";
    officerIdToWasteManagementOfficer[officerId].wasteWeight = 0;
    officerIdToWasteManagementOfficer[officerId].transportationRequestDate = 0;
    delete _officerIdToWasteTypes[officerId]; 
    wasteToBeTransported[officerId] = false;

    WasteCollector memory wasteCollector = driverIdToWasteCollector[driverId];
    wasteCollector.wasteId = wasteId;
    wasteCollector.wasteWeight = wasteWeight;
    _driverIdToWasteTypes[driverId] = wasteTypes;

    driverIdToWasteCollector[driverId] = wasteCollector;

    emit transportationAccepted(driverId, wasteId, wasteWeight, wasteTypes, block.timestamp); 
  }

  function requestTreatment(string memory driverId) public onlyDriver(driverId) {
    wasteToBeTreated[driverId] = true;

    string memory wasteId = driverIdToWasteCollector[driverId].wasteId;
    uint64 wasteWeight = driverIdToWasteCollector[driverId].wasteWeight;
    WasteType[] memory wasteTypes = _driverIdToWasteTypes[driverId];

    emit treatmentRequested(driverId, wasteId, wasteWeight, wasteTypes);
  }

  function acceptTreatment(string memory facilityId, string memory driverId, string memory wasteImage) public onlyFacility(facilityId) {
    WasteCollector memory wasteCollector = driverIdToWasteCollector[driverId];
    string memory wasteId = wasteCollector.wasteId;
    uint64 wasteWeight = wasteCollector.wasteWeight;
    WasteType[] memory wasteTypes = _driverIdToWasteTypes[driverId];

    driverIdToWasteCollector[driverId].wasteId = "";
    driverIdToWasteCollector[driverId].wasteWeight = 0;
    delete _driverIdToWasteTypes[driverId];
    wasteToBeTreated[driverId] = false;

    TreatmentFacility memory treatmentFacility = facilityIdToTreatmentFacility[facilityId];
    treatmentFacility.wasteId = wasteId;
    treatmentFacility.wasteWeight = wasteWeight;
    treatmentFacility.wasteImage = wasteImage;
    treatmentFacility.arrivalDate = block.timestamp;
    _facilityIdToWasteTypes[facilityId] = wasteTypes;

    facilityIdToTreatmentFacility[facilityId] = treatmentFacility;

    emit treatmentAccepted(facilityId, wasteId, wasteWeight, wasteTypes, block.timestamp);
  }

  function shareShipmentData(string memory facilityId) public onlyFacility(facilityId) {
    TreatmentFacility memory treatmentFacility = facilityIdToTreatmentFacility[facilityId];
    string memory wasteId = treatmentFacility.wasteId;
    uint64 wasteWeight = treatmentFacility.wasteWeight;
    string memory wasteImage = treatmentFacility.wasteImage;
    WasteType[] memory wasteTypes = _facilityIdToWasteTypes[facilityId];

    emit shipmentData(wasteId, wasteWeight, wasteTypes, wasteImage);
  }

  function confirmShipment(string memory facilityId) public onlyFacility(facilityId) {
    string memory wasteId = facilityIdToTreatmentFacility[facilityId].wasteId;
    uint64 wasteWeight = facilityIdToTreatmentFacility[facilityId].wasteWeight;
    string memory wasteImage = facilityIdToTreatmentFacility[facilityId].wasteImage;
    WasteType[] memory wasteTypes = _facilityIdToWasteTypes[facilityId];

    facilityIdToTreatmentFacility[facilityId].wasteId = "";
    facilityIdToTreatmentFacility[facilityId].wasteWeight = 0;
    facilityIdToTreatmentFacility[facilityId].wasteImage = "";
    delete _facilityIdToWasteTypes[facilityId];

    emit shipmentConfirmed(wasteId, wasteWeight, wasteTypes, wasteImage, block.timestamp);
  }

  function issueFine(address payable feeCollectionAddress, string memory recipientName, string memory recipientId, uint256 amountInWei) public onlyOwner {
    address payable fineRecipient;

    if (keccak256(bytes(recipientName)) == keccak256(bytes("Waste Collector"))) {
      require(amountInWei <= collectorDeposits[recipientId], "rejected: insufficient deposit amount for fine");
      feeCollectionAddress.transfer(amountInWei);
      uint256 reimbursement = collectorDeposits[recipientId] - amountInWei;
      fineRecipient = _driverIdToAddress[recipientId];
      fineRecipient.transfer(reimbursement);
      
    } else if (keccak256(bytes(recipientName)) == keccak256(bytes("Treatment Facility"))) {
      require(amountInWei <= facilityDeposits[recipientId], "rejected: insufficient deposit amount for fine");
      feeCollectionAddress.transfer(amountInWei);
      uint256 reimbursement = facilityDeposits[recipientId] - amountInWei;
      fineRecipient = _facilityIdToAddress[recipientId];
      fineRecipient.transfer(reimbursement);
    }

    emit fineIssued(fineRecipient, recipientId, recipientName, amountInWei);
  }

  function returnDeposit(string memory recipientName, string memory recipientId) public onlyOwner {
    address payable depositRecipient;

    if (keccak256(bytes(recipientName)) == keccak256(bytes("Waste Collector"))) {
      depositRecipient = _driverIdToAddress[recipientId];
      depositRecipient.transfer(1000000000000000000 wei);

    } else if (keccak256(bytes(recipientName)) == keccak256(bytes("Treatment Facility"))) {
      depositRecipient = _facilityIdToAddress[recipientId];
      depositRecipient.transfer(1000000000000000000 wei);
    } 

    emit depositReturned(depositRecipient, recipientId, recipientName);
  }
}