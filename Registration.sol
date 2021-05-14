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

// Registration contract for HCW supply chain management
contract Registration is AccessControl {
  /*** EVENTS ***/

  // Emit when a new actor is added or removed from mapping.
  event actorModified(string actorId, string actorRole, string actorLicense, bool actorApproved);

  // Emit when an actor is approved or unapproved.
  event actorApprovalChanged(string actorId, bool actorApproved);

  /*** DATA STRUCTURES ***/

  // Stores all necessary data for an actor.
  struct Actor {
    string actorId;
    string actorRole;
    string actorLicense;
    bool actorApproved;
  }

  /*** STORAGE ***/

  // Mapping from each actor's id to their respective struct.
  mapping(string => Actor) private _idToActor;

  // Store total actors as integer.
  uint256 private _totalActors;

  // Set total number of actors to 0 on contract deployment.
  constructor() {
    _totalActors = 0;
  }

  // Get actor data from Id.
  // actorId Unique Id of actor.
  /// @return Actor struct from specified Id.
  function actorFromId(string memory actorId) public view onlyOwner returns(Actor memory) {
    return _idToActor[actorId];
  }

  // Add new actor to mapping.
  // actorId Unique Id of actor.
  // actorRole Actor's role.
  // actorLicense IPFS hash to actor's license.
  // actorApproved Approved to operate or not.
  function addActor(string memory actorId, string memory actorRole, 
  string memory actorLicense, bool actorApproved) public onlyOwner {
    Actor memory newActor = Actor(
      actorId,
      actorRole,
      actorLicense,
      actorApproved
    );

    _idToActor[actorId] = newActor;
    _totalActors++;
    emit actorModified(actorId, actorRole, actorLicense, actorApproved);
  }

  // Remove actor from mapping.
  // actorId Unique Id of actor
  function removeActor(string memory actorId) public onlyOwner {
    Actor memory actor = _idToActor[actorId];
    string memory _actorId = actor.actorId;
    string memory _actorRole = actor.actorRole;
    string memory _actorLicense = actor.actorLicense;
    bool _actorApproved = actor.actorApproved;

    emit actorModified(_actorId, _actorRole, _actorLicense, _actorApproved);
    delete _idToActor[actorId];
    _totalActors--;
  }

  function setActorApproved(string memory actorId, bool approved) public onlyOwner {
    Actor memory actor = _idToActor[actorId];
    actor.actorApproved = approved;

    _idToActor[actorId] = actor;
    emit actorApprovalChanged(actorId, approved);
  }

  // Return total number of actors.
  function totalActors() public view onlyOwner returns(uint256) {
    return _totalActors;
  }
}