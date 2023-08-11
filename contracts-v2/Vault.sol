// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS, Attestation, AttestationRequest, AttestationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/EAS.sol";

contract Vault {
    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    IEAS public immutable i_eas;
    address public immutable i_atestamint;
    bytes32 public immutable i_schemaId;

    address public nftContract;
    uint public editionSize;
    bool public initialized;
    uint public positiveVotes = 0;
    uint public negativeVotes = 0;

    mapping(uint256 => bool) public tokenIdVoted;
    mapping(uint256 => bool) public uniqueHumanVoted;

    IWorldID internal immutable worldId;
    uint256 internal immutable externalNullifier;
    uint256 internal immutable groupId = 0;

    event Voted(
        address voter,
        uint256 tokenId,
        uint256 nulllifierHash,
        bool isFor
    );

    event FundsUnlocked(
        address creator,
        uint256 amount,
        uint256 forVotes,
        uint256 editionSize
    );

    constructor(
        IEAS eas,
        IWorldID _worldId,
        string memory _appId,
        string memory _actionId,
        bytes32 schemaId,
        address atestamint
    ) SchemaResolver(eas) {
        i_eas = eas;
        i_atestamint = atestamint;
        i_schemaId = schemaId;
        worldId = _worldId;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
    }

    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
    }

    modifier onlyAtestamint() {
        require(msg.sender == i_atestamint, "Inavlid sender");
        _;
    }

    function setup(
        address _nftContract,
        address _safeAddress,
        uint256 _editionSize
    ) public onlyOnce onlyAtestamint {
        nftContract = _nftContract;
        safeAddress = _safeAddress;
        editionSize = _editionSize;
        initialized = true;
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal view override returns (bool) {}

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        return true;
    }

    function vote(
        AttestationRequest calldata request,
        uint256 tokenId,
        Vote _vote,
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        require(uniqueHumanVoted[nullifierHash] == false, "Unique Human voted");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "Not owner"
        );
        require(tokenIdVoted[tokenId] == false, "Token voted");

        verifyWorldCoin(root, signal, nullifierHash, proof);

        i_eas.attest(request);
        tokenIdVoted[tokenId] = true;
        uniqueHumanVoted[nullifierHash] = true;
        if (_vote == Vote.For) {
            forVotes += 1;
        }
        emit Voted(msg.sender, tokenId, nullifierHash, _vote);
    }

    function verifyWorldCoin(
        uint256 root,
        address signal,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );
    }

    function attestEAS(
        string calldata description,
        bool isPositive,
        bytes32 refuid,
        uint value
    ) public payable {
        AttestationRequestData memory requestData = AttestationRequestData(
            address(this),
            type(uint64).max,
            false,
            bytes32(0),
            abi.encode(msg.sender, description, isPositive),
            value
        );
        AttestationRequest memory request = AttestationRequest(
            refuid,
            requestData
        );
        i_eas.attest(request);
    }

    function unlockFunds() public {
        uint editionSize = IGetConfigZora(nftContract).config().editionSize;
        address creator = getCreator();
        require(forVotes > editionSize / 2, "Not owner");

        GnosisSafe(safeAddress).execTransactionFromModule(
            creator,
            safeAddress.balance,
            "",
            Enum.Operation.Call
        );

        emit FundsUnlocked(creator, safeAddress.balance, forVotes, editionSize);
    }

    function getCreator() public view returns (address) {
        uint256 length = address(this).code.length;
        return
            abi.decode(
                Bytecode.codeAt(address(this), length - 0x20, length),
                (address)
            );
    }
}
