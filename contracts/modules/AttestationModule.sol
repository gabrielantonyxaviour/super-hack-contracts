// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "../utils/Enum.sol";
import "../utils/SignatureDecoder.sol";
import "../utils/Bytecode.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ByteHasher} from "../utils/ByteHasher.sol";
import {IWorldID} from "../interface/IWorldID.sol";
import {SchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/SchemaResolver.sol";
import {IEAS,Attestation,AttestationRequest,AttestationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/EAS.sol";
import "../interface/IGnosisSafe.sol";
import "../interface/IGetConfigZora.sol";

contract AttestationModule is SignatureDecoder,SchemaResolver{
    using ByteHasher for bytes;

    enum Vote{
        For,
        Against,
        Abstain
    }

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    IEAS public immutable i_eas;
    address public immutable i_atestamint;
    address public  nftContract;
    address public  safeAddress;
    bytes32 public  schemaId;

    bool public initialized;

    mapping(uint256 => bool) public tokenIdVoted;
    mapping(uint256 => bool) public uniqueHumanVoted;

    uint public forVotes=0;

    /// @notice Thrown when attempting to reuse a nullifier

    /// @dev The address of the World ID Router contract that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The keccak256 hash of the externalNullifier (unique identifier of the action performed), combination of appId and action
    uint256 internal immutable externalNullifier;

    /// @dev The World ID group ID (1 for Orb-verified, 0 for Phone-verified)
    uint256 internal immutable groupId = 0;

    event Voted(
        address indexed voter,
        uint256 indexed tokenId,
        uint256 nulllifierHash,
        Vote _vote
    );
    
    event FundsUnlocked(
        address  creator,
        uint256  amount,
        uint256  forVotes,
        uint256 editionSize
    );
    
    constructor(
         IEAS eas,
    IWorldID _worldId,
    string memory _appId,
    string memory _actionId,
    address atestamint) SchemaResolver(eas) 
    {
        i_eas = eas;
        i_atestamint=atestamint;
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
        bytes32 _schemaId
    ) public onlyOnce onlyAtestamint {
        nftContract = _nftContract;
        safeAddress=_safeAddress;
        schemaId = _schemaId;
        initialized = true;
    }

    function onAttest(Attestation calldata attestation, uint256 /*value*/) internal view override returns (bool) {
        return true;
    }

    function onRevoke(Attestation calldata /*attestation*/, uint256 /*value*/) internal pure override returns (bool) {
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

        verifyWorldCoin(root,signal,nullifierHash,proof);

        i_eas.attest(request);
        tokenIdVoted[tokenId] = true;
        uniqueHumanVoted[nullifierHash] = true;
        if(_vote==Vote.For)
        {
            forVotes+=1;
        }
        emit Voted(msg.sender, tokenId, nullifierHash, _vote);
    }

    function verifyWorldCoin(uint256 root,address signal,uint256 nullifierHash,uint256[8] calldata proof)public {
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );
    }

    function attestEAS(string calldata description,bool isPositive,bytes32 refuid,uint value) public payable{
        AttestationRequestData memory requestData=AttestationRequestData(address(this),type(uint64).max,false,bytes32(0),abi.encode(msg.sender,description,isPositive),value);
        AttestationRequest memory request=AttestationRequest(refuid,requestData);
        i_eas.attest(request);
    }

    function unlockFunds() public {
        uint editionSize=IGetConfigZora(nftContract).config().editionSize;
        address creator=getCreator();
        require(forVotes>editionSize/2, "Not owner");

        GnosisSafe(safeAddress).execTransactionFromModule(
            creator,
            safeAddress.balance,
            "",
            Enum.Operation.Call
        );

        emit FundsUnlocked(creator, safeAddress.balance,forVotes,editionSize);
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
