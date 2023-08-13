// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation, AttestationRequest, AttestationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/EAS.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./utils/Bytecode.sol";
import {ByteHasher} from "./utils/ByteHasher.sol";
import {IWorldID} from "./interface/IWorldID.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";

contract Vault is SchemaResolver {
    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    IEAS public immutable i_eas;

    address public nftContract;
    address public creator;
    address public immutable i_atestamint;
    bytes32 public immutable i_schemaId;
    uint64 public editionSize;
    bool public initialized;
    uint public positiveVotes = 0;
    uint public negativeVotes = 0;

    mapping(uint256 => bool) public tokenIdVoted;
    mapping(uint256 => bool) public uniqueHumanVoted;

    IWorldID internal immutable worldId;
    uint256 internal immutable externalNullifier;
    uint256 internal immutable groupId = 1;

    event Voted(
        address voter,
        uint256 tokenId,
        string description,
        uint256 nulllifierHash,
        bool isFor
    );

    event FundsUnlocked(uint256 amount, uint256 forVotes, uint64 editionSize);

    constructor(
        IEAS eas,
        IWorldID _worldId,
        string memory _appId,
        string memory _actionId,
        address _atestamint,
        bytes32 schemaId
    ) SchemaResolver(eas) {
        i_eas = eas;
        i_schemaId = schemaId;
        worldId = _worldId;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
        i_atestamint = _atestamint;
    }

    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
    }

    function setup(
        address _nftContract,
        address _creator,
        uint64 _editionSize
    ) public onlyOnce {
        nftContract = _nftContract;
        creator = _creator;
        editionSize = _editionSize;
        initialized = true;
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    function vote(
        uint256 tokenId,
        string memory description,
        bool isPositive,
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) public payable {
        _verifyConditions(nftContract, msg.sender, tokenId, nullifierHash);
        _verifyUniqueHuman(signal, root, nullifierHash, proof);
        _attestEAS(tokenId, description, isPositive);
        tokenIdVoted[tokenId] = true;
        uniqueHumanVoted[nullifierHash] = true;
        if (isPositive == true) {
            positiveVotes += 1;
        } else {
            negativeVotes += 1;
        }

        emit Voted(msg.sender, tokenId, description, nullifierHash, isPositive);
    }

    function _attestEAS(
        uint256 tokenId,
        string memory description,
        bool isPositive
    ) internal {
        AttestationRequestData memory requestData = AttestationRequestData(
            address(this),
            type(uint64).max,
            false,
            bytes32(0),
            abi.encode(nftContract, tokenId, description, isPositive),
            msg.value
        );
        AttestationRequest memory request = AttestationRequest(
            i_schemaId,
            requestData
        );
        i_eas.attest(request);
    }

    function _verifyConditions(
        address _nftContract,
        address attester,
        uint256 tokenId,
        uint256 nullifierHash
    ) internal view {
        require(
            IERC721(_nftContract).ownerOf(tokenId) == attester,
            "Not owner"
        );
        require(tokenIdVoted[tokenId] == false, "Token voted");
        require(uniqueHumanVoted[nullifierHash] == false, "Unique Human voted");
    }

    function _verifyUniqueHuman(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) internal {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );
    }

    function unlockFunds() public {
        require(positiveVotes >= editionSize / 2, "Criteria not met");
        uint totalFunds = address(this).balance;
        (bool success, ) = creator.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit FundsUnlocked(totalFunds, positiveVotes, editionSize);
    }
}
