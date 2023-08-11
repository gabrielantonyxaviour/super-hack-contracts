// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "../utils/Enum.sol";
import "../utils/SignatureDecoder.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IEAS.sol";
import {ByteHasher} from "../utils/ByteHasher.sol";
import {IWorldID} from "../interface/IWorldID.sol";

import "../interface/IGnosisSafe.sol";

contract MockAttestationModule is SignatureDecoder {
    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    // IEAS public immutable i_eas;
    address public creator;
    address public nftContract;
    bytes32 public schemaId;

    bool public initialized;

    mapping(uint256 => bool) public tokenIdVoted;
    mapping(uint256 => bool) public uniqueHumanVoted;

    /// @notice Thrown when attempting to reuse a nullifier

    /// @dev The address of the World ID Router contract that will be used for verifying proofs
    // IWorldID internal immutable worldId;

    /// @dev The keccak256 hash of the externalNullifier (unique identifier of the action performed), combination of appId and action
    // uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (1 for Orb-verified, 0 for Phone-verified)
    uint256 internal immutable groupId = 1;

    constructor() // IEAS eas,
    // IWorldID _worldId,
    // string memory _appId,
    // string memory _actionId
    {
        // i_eas = eas;
        // worldId = _worldId;
        // externalNullifier = abi
        //     .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
        //     .hashToField();
    }

    event Voted(
        address indexed voter,
        uint256 indexed tokenId,
        uint256 nulllifierHash,
        bool isPositive
    );

    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
    }

    function setup(
        address _creator,
        address _nftContract,
        bytes32 _schemaId
    ) public onlyOnce {
        initialized = true;
        creator = _creator;
        nftContract = _nftContract;
        schemaId = _schemaId;
    }

    function vote(
        IEAS.AttestationRequest calldata request,
        uint256 tokenId,
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        bool isPositive
    ) public {
        require(request.schema == schemaId, "Invalid schema");
        emit Voted(msg.sender, tokenId, nullifierHash, isPositive);
        // require(uniqueHumanVoted[nullifierHash] == false, "Unique Human voted");
        // require(
        //     IERC721(nftContract).ownerOf(tokenId) == msg.sender,
        //     "Not owner"
        // );
        // require(tokenIdVoted[tokenId] == false, "Token voted");
        // worldId.verifyProof(
        //     root,
        //     groupId,
        //     abi.encodePacked(signal).hashToField(),
        //     nullifierHash,
        //     externalNullifier,
        //     proof
        // );
        // i_eas.attest(request);
        // uniqueHumanVoted[nullifierHash] = true;
        // tokenIdVoted[tokenId] = true;
    }
}
