pragma solidity =0.4.21;
pragma experimental ABIEncoderV2;

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
  function AccessControl() public {
    _owner = msg.sender;
    emit ownershipTransferred(address(0), _owner);
  }
  
  // Transfer ownership of contract to Address of new owner. 
  function transferOwnership(address to) public onlyOwner {
    require(to != address(0));
    emit ownershipTransferred(_owner, to);
    _owner = to;
  }
}

// Onsite Handling contract for HCW supply chain management
contract Handling is AccessControl {
  /*** EVENTS ***/

  // Emit when each new stakeholder is created.
  event medicalUnitCreated(address unitAddress, string unitName, string unitId);

  event wasteHandlingStaffCreated(address staffAddress, string staffName, string staffId);

  event onSiteStorageCreated(address storageUnitAddress, string storageUnitId, string storageStaffName, string storageStaffId);

  event wasteManagementOfficerCreated(address officerAddress, string officerName, string officerId, string hospitalName, string hospitalId);
  
  // Emit when new waste collection request is made.
  event collectionRequested(string unitId, string wasteId, uint64 wasteWeight, WasteType wasteType, uint256 generationDate);

  // Emit when waste collection request is accepted.
  event collectionAccepted(string unitId, string staffId, string wasteId, uint64 wasteWeight, WasteType wasteType, uint256 collectionDate);

  // Emit when new storage request is made.
  event storageRequested(string staffId, string wasteId, uint64 wasteWeight, WasteType wasteType, uint256 collectionDate);

  // Emit when waste is stored.
  event wasteStored(string storageUnitId, string wasteId, uint64 wasteWeight, WasteType wasteType, uint256 storeDate);

  // Emit when transportation request is made.
  event transportationRequested(string storageUnitId, string[] cumulativeWasteIds, uint64 cumulativeWasteWeight,WasteType[] cumulativeWasteTypes, uint256 requestDate);

  // Emit when transportation is authorized.
  event transportationAuthorized(string officerId, string storageUnitId, string[] cumulativeWasteIds, uint64 cumulativeWasteWeight, WasteType[] cumulativeWasteTypes, 
  uint256 requestDate, string hospitalName, string hospitalId);

  // Emit when storage at max capacity.
  event storageAtCapacity(string storageUnitId, uint256 wasteAmount);

  /*** MODIFIERS ***/

  // Functions with modifier can only be called when sender's address is paired with stakeholder Id.
  
  modifier onlyMedicalUnit(string memory unitId) {
    require(_unitIdToAddress[unitId] == msg.sender);
    _;
  }

  modifier onlyWasteHandling(string memory staffId) {
    require(_staffIdToAddress[staffId] == msg.sender);
    _;
  }

  modifier onlyOnSiteStorage(string memory storageUnitId) {
    require(_storageUnitIdToAddress[storageUnitId] == msg.sender);
    _;
  }

  modifier onlyOfficer(string memory officerId) {
    require(_officerIdToAddress[officerId] == msg.sender);
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
  
  struct MedicalUnit {address unitAddress; string unitName; string unitId; string wasteId; uint64 wasteWeight; WasteType wasteType; uint256 generationDate;}

  struct WasteHandlingStaff {address staffAddress; string staffName; string staffId; string wasteId; uint64 wasteWeight; WasteType wasteType; uint256 collectionDate;}

  struct OnSiteStorage {address storageUnitAddress; string storageUnitId; string storageStaffName; string storageStaffId; uint64 cumulativeWasteWeight; uint256 requestDate;}

  struct WasteManagementOfficer {address officerAddress; string officerName; string officerId; string hospitalName; string hospitalId; string storageStaffName;
    string storageStaffId; string[] cumulativeWasteIds; uint256 cumulativeWasteWeight; WasteType[] cumulativeWasteTypes; string[] wasteImages; uint256 transportationRequestDate;}

  /*** STORAGE ***/

  // Declare max number of waste objects that can be stored.
  uint256 constant maxCapacity = 50;

  mapping(string => MedicalUnit) private unitIdToMedicalUnit;
  mapping(string => address) private _unitIdToAddress;
  mapping(string => WasteHandlingStaff) private staffIdToWasteHandlingStaff;
  mapping(string => address) private _staffIdToAddress;
  mapping(string => OnSiteStorage) private storageUnitIdToOnSiteStorage;
  mapping(string => address) private _storageUnitIdToAddress;
  mapping(string => string[]) private _storageUnitIdToCumulativeWasteIds;
  mapping(string => WasteType[]) private _storageUnitIdToCumulativeWasteTypes;
  mapping(string => string[]) private _storageUnitIdToWasteImages;
  mapping(string => WasteManagementOfficer) private officerIdToWasteManagementOfficer;
  mapping(string => address) private _officerIdToAddress;
  mapping(string => bool) private wasteToBeCollected; 
  mapping(string => bool) private wasteToBeStored; 
  mapping(string => bool) private storedWaste;
  mapping(string => bool) private toBeTransported;

  // Create new stakeholder and create event.

  function addMedicalUnit(address unitAddress, string memory unitName, string memory unitId) public onlyOwner {
    MedicalUnit memory newMedicalUnit;
    newMedicalUnit.unitAddress = unitAddress;
    newMedicalUnit.unitName = unitName;
    newMedicalUnit.unitId = unitId;

    unitIdToMedicalUnit[unitId] = newMedicalUnit;
    _unitIdToAddress[unitId] = unitAddress;
    emit medicalUnitCreated(unitAddress, unitName, unitId);
  }

  function addWasteHandlingStaff(address staffAddress, string memory staffName, string memory staffId) public onlyOwner {
    WasteHandlingStaff memory newWasteHandlingStaff;
    newWasteHandlingStaff.staffAddress = staffAddress;
    newWasteHandlingStaff.staffName = staffName;
    newWasteHandlingStaff.staffId = staffId;

    staffIdToWasteHandlingStaff[staffId] = newWasteHandlingStaff;
    _staffIdToAddress[staffId] = staffAddress;
    emit wasteHandlingStaffCreated(staffAddress, staffName, staffId);
  }

  function addOnSiteStorage(address storageUnitAddress, string memory storageStaffName, string memory storageStaffId, string memory storageUnitId ) public onlyOwner {
    OnSiteStorage memory newOnSiteStorage;
    newOnSiteStorage.storageUnitAddress = storageUnitAddress;
    newOnSiteStorage.storageUnitId = storageUnitId;
    newOnSiteStorage.storageStaffName = storageStaffName;
    newOnSiteStorage.storageStaffId = storageStaffId;

    storageUnitIdToOnSiteStorage[storageUnitId] = newOnSiteStorage;
    _storageUnitIdToAddress[storageUnitId] = storageUnitAddress;
    emit onSiteStorageCreated(storageUnitAddress, storageUnitId, storageStaffName, storageStaffId);
  }

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

  function requestCollection(string memory unitId, string memory wasteId, uint64 wasteWeight, WasteType wasteType) public onlyMedicalUnit(unitId) {
    uint256 _timestamp = block.timestamp;

    MedicalUnit memory medicalUnit = unitIdToMedicalUnit[unitId];
    medicalUnit.wasteId = wasteId;
    medicalUnit.wasteWeight = wasteWeight;
    medicalUnit.wasteType = wasteType;
    medicalUnit.generationDate = _timestamp;

    unitIdToMedicalUnit[unitId] = medicalUnit;
    wasteToBeCollected[unitId] = true;
    emit collectionRequested(unitId, wasteId, wasteWeight, wasteType, _timestamp);
  }

  function acceptCollection(string memory staffId, string memory unitId) public onlyWasteHandling(staffId) {
    require(wasteToBeCollected[unitId]);

    MedicalUnit memory medicalUnit = unitIdToMedicalUnit[unitId];
    string memory wasteId = medicalUnit.wasteId;
    uint64 wasteWeight = medicalUnit.wasteWeight;
    WasteType wasteType = medicalUnit.wasteType;

    unitIdToMedicalUnit[unitId].wasteId = "";
    unitIdToMedicalUnit[unitId].wasteWeight = 0;
    unitIdToMedicalUnit[unitId].wasteType = WasteType.None;
    unitIdToMedicalUnit[unitId].generationDate = 0;
    wasteToBeCollected[unitId] = false;

    uint256 _timestamp = block.timestamp;

    WasteHandlingStaff memory wasteHandlingStaff = staffIdToWasteHandlingStaff[staffId];
    wasteHandlingStaff.wasteId = wasteId;
    wasteHandlingStaff.wasteWeight = wasteWeight;
    wasteHandlingStaff.wasteType = wasteType;
    wasteHandlingStaff.collectionDate = _timestamp;

    staffIdToWasteHandlingStaff[staffId] = wasteHandlingStaff;
    emit collectionAccepted(unitId, staffId, wasteId, wasteWeight, wasteType, _timestamp); 
  }

  function requestStorage(string memory staffId) public onlyWasteHandling(staffId) {
    wasteToBeStored[staffId] = true;

    WasteHandlingStaff memory wasteHandlingStaff = staffIdToWasteHandlingStaff[staffId];
    string memory wasteId = wasteHandlingStaff.wasteId;
    uint64 wasteWeight = wasteHandlingStaff.wasteWeight;
    WasteType wasteType = wasteHandlingStaff.wasteType;
    uint256 collectionDate = wasteHandlingStaff.collectionDate;

    emit storageRequested(staffId, wasteId, wasteWeight, wasteType, collectionDate);
  }
  
  function acceptStorage(string memory storageUnitId, string memory staffId, string memory imageHash) public onlyOnSiteStorage(storageUnitId) {
    require(wasteToBeStored[staffId]);

    WasteHandlingStaff memory wasteHandlingStaff = staffIdToWasteHandlingStaff[staffId];
    string memory wasteId = wasteHandlingStaff.wasteId;
    uint64 wasteWeight = wasteHandlingStaff.wasteWeight;
    WasteType wasteType = wasteHandlingStaff.wasteType;

    staffIdToWasteHandlingStaff[staffId].wasteId = "";
    staffIdToWasteHandlingStaff[staffId].wasteWeight = 0;
    staffIdToWasteHandlingStaff[staffId].wasteType = WasteType.None;
    staffIdToWasteHandlingStaff[staffId].collectionDate = 0;
    wasteToBeStored[staffId] = false;

    storageUnitIdToOnSiteStorage[storageUnitId].cumulativeWasteWeight += wasteWeight;
    _storageUnitIdToCumulativeWasteIds[storageUnitId].push(wasteId);
    _storageUnitIdToCumulativeWasteTypes[storageUnitId].push(wasteType);
    _storageUnitIdToWasteImages[storageUnitId].push(imageHash);
    storedWaste[storageUnitId] = true;

    emit wasteStored(storageUnitId, wasteId, wasteWeight, wasteType, block.timestamp);
  }

  function requestTransportation(string memory storageUnitId) public onlyOnSiteStorage(storageUnitId) {
    toBeTransported[storageUnitId] = true;

    uint64 cumulativeWasteWeight = storageUnitIdToOnSiteStorage[storageUnitId].cumulativeWasteWeight;
    string[] memory cumulativeWasteIds = _storageUnitIdToCumulativeWasteIds[storageUnitId];
    WasteType[] memory cumulativeWasteTypes = _storageUnitIdToCumulativeWasteTypes[storageUnitId];

    emit transportationRequested(storageUnitId, cumulativeWasteIds, cumulativeWasteWeight, cumulativeWasteTypes, block.timestamp);
  }

  function authorizeRequest(
    string memory storageUnitId,
    string memory officerId
  ) public onlyOfficer(officerId) {
    uint64 cumulativeWasteWeight = storageUnitIdToOnSiteStorage[storageUnitId].cumulativeWasteWeight;
    string[] memory cumulativeWasteIds = _storageUnitIdToCumulativeWasteIds[storageUnitId];
    WasteType[] memory cumulativeWasteTypes = _storageUnitIdToCumulativeWasteTypes[storageUnitId];
    uint256 requestDate = storageUnitIdToOnSiteStorage[storageUnitId].requestDate;

    storageUnitIdToOnSiteStorage[storageUnitId].cumulativeWasteWeight = 0;
    delete _storageUnitIdToCumulativeWasteIds[storageUnitId];
    delete _storageUnitIdToCumulativeWasteTypes[storageUnitId];
    delete _storageUnitIdToWasteImages[storageUnitId];
    storageUnitIdToOnSiteStorage[storageUnitId].requestDate = 0;
    storedWaste[storageUnitId] = false;

    string memory hospitalName = officerIdToWasteManagementOfficer[officerId].hospitalName;
    string memory hospitalId = officerIdToWasteManagementOfficer[officerId].hospitalId;
    
    emit transportationAuthorized(officerId, storageUnitId, cumulativeWasteIds, cumulativeWasteWeight, cumulativeWasteTypes, requestDate, hospitalName, hospitalId);
  }

  function storageLimit(string memory storageUnitId) public onlyOnSiteStorage(storageUnitId) {
    uint256 capacity = _storageUnitIdToCumulativeWasteIds[storageUnitId].length; 
    emit storageAtCapacity(storageUnitId, capacity);
  }
}