pragma solidity ^0.8.7;

import "./interface/IZoraFactory.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract AtestamintV2 {
    IZoraFactory public immutable i_zoraNftFactory;
    address public immutable i_vaultImplementation;

    struct CreateDropInputParams {
        string name;
        string symbol;
        uint64 editionSize;
        uint16 royaltyBPS;
        IERC721Drop.SalesConfiguration saleConfig;
        string metadataURIBase;
        string metadataContractURI;
        uint salt;
    }

    struct CreateEditionInputParams {
        string name;
        string symbol;
        uint64 editionSize;
        uint16 royaltyBPS;
        IERC721Drop.SalesConfiguration saleConfig;
        string description;
        string animationURI;
        string imageURI;
        uint salt;
    }

    bytes4 public constant SETUP_VAULT_METHOD_ID = bytes4(keccak256("setup(address,address,uint256)"));

    constructor(
        IZoraFactory zoraNftFactory,
        address vaultImplementation
    ) {
        i_zoraNftFactory = zoraNftFactory;
        i_vaultImplementation = vaultImplementation;
    }

    event EditionCreated(
        address  creator,
        address  editionAddress,
        address vaultAddress
    );
    event DropCreated(address  creator, address  dropAddress,address vaultAddress);


    function createDropCollection(
        CreateDropInputParams memory inputParams
    ) public {
        address vaultAddress = _deployProxy(
            i_vaultImplementation,
            inputParams.salt
        );
    
        address dropAddress = i_zoraNftFactory.createDrop(
            inputParams.name,
            inputParams.symbol,
            vaultAddress,
            inputParams.editionSize,
            inputParams.royaltyBPS,
            payable(vaultAddress),
            inputParams.saleConfig,
            inputParams.metadataURIBase,
            inputParams.metadataContractURI
        );
        bytes memory setupData=abi.encodeWithSelector(
                    SETUP_VAULT_METHOD_ID,
                   dropAddress,
                   msg.sender,
                   inputParams.editionSize
                );
        (bool success, ) =vaultAddress.call(setupData);
        require(success,"Setup Failed");
        emit DropCreated(msg.sender, dropAddress,vaultAddress);
    }

    function createEditionCollection(
        CreateEditionInputParams memory inputParams
    ) public {
        
  address vaultAddress = _deployProxy(
            i_vaultImplementation,
            inputParams.salt
        );
  
        address editionAddress = i_zoraNftFactory.createEdition(
            inputParams.name,
            inputParams.symbol,
            inputParams.editionSize,
            inputParams.royaltyBPS,
            payable(vaultAddress),
            vaultAddress,
            inputParams.saleConfig,
            inputParams.description,
            inputParams.animationURI,
            inputParams.imageURI
        );
        bytes memory setupData=abi.encodeWithSelector(
                    SETUP_VAULT_METHOD_ID,
            editionAddress,
                   msg.sender,
                   inputParams.editionSize
                );
        (bool success, ) =vaultAddress.call(setupData);
        require(success,"Setup Failed");
        emit EditionCreated(msg.sender, editionAddress,vaultAddress);
    }

    function _deployProxy(
        address implementation,
        uint salt
    ) public returns (address _contractAddress) {
        bytes memory code = _creationCode(implementation, salt);
        _contractAddress = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );
        if (_contractAddress.code.length != 0) return _contractAddress;

        _contractAddress = Create2.deploy(0, bytes32(salt), code);
    }

    function _creationCode(
        address implementation_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_)
            );
    }
}