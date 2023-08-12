pragma solidity ^0.8.7;

import "./interface/IZoraFactory.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Atestamint {
    IZoraFactory public immutable i_zoraNftFactory;
    address public immutable i_safeImplementation;
    address public immutable i_guardImplementation;
    address public immutable i_moduleImplementation;

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

    constructor(
        IZoraFactory zoraNftFactory,
        address safeImplementation,
        address guardImplementation,
        address moduleImplementation
    ) {
        i_zoraNftFactory = zoraNftFactory;
        i_safeImplementation = safeImplementation;
        i_guardImplementation = guardImplementation;
        i_moduleImplementation = moduleImplementation;
    }

    event EditionCreated(
        address indexed creator,
        address indexed editionAddress
    );
    event DropCreated(address indexed creator, address indexed dropAddress);

    event GuardDeployed(address guardAddress);
    event ModuleDeployed(address moduleAddress);
    event SafeDeployed(address safeAddress);

    function createDropCollection(
        CreateDropInputParams memory inputParams
    ) public {
        address guardAddress = _deployProxy(
            i_guardImplementation,
            msg.sender,
            inputParams.salt
        );

        address moduleAddress = _deployProxy(
            i_moduleImplementation,
            msg.sender,
            inputParams.salt
        );

        address safeAddress = _deployProxy(
            i_safeImplementation,
            msg.sender,
            inputParams.salt
        );
        
        address dropAddress = i_zoraNftFactory.createDrop(
            inputParams.name,
            inputParams.symbol,
            safeAddress,
            inputParams.editionSize,
            inputParams.royaltyBPS,
            payable(safeAddress),
            inputParams.saleConfig,
            inputParams.metadataURIBase,
            inputParams.metadataContractURI
        );

        emit DropCreated(msg.sender, dropAddress);
    }

    function createEditionCollection(
        CreateEditionInputParams memory inputParams
    ) public {
        address guardAddress = _deployProxy(
            i_guardImplementation,
            msg.sender,
            inputParams.salt
        );

        address moduleAddress = _deployProxy(
            i_moduleImplementation,
            msg.sender,
            inputParams.salt
        );

        address safeAddress = _deployProxy(
            i_safeImplementation,
            msg.sender,
            inputParams.salt
        );
        // bytes4 methodId = bytes4(keccak256("setup(address,address)"));
        // (bool success, ) = guardAddress.call(
        //     abi.encodeWithSelector(methodId, safeAddress, moduleAddress)
        // );
        // if (!success) {
        //     revert("Create Failed");
        // }
        address editionAddress = i_zoraNftFactory.createEdition(
            inputParams.name,
            inputParams.symbol,
            inputParams.editionSize,
            inputParams.royaltyBPS,
            payable(safeAddress),
            safeAddress,
            inputParams.saleConfig,
            inputParams.description,
            inputParams.animationURI,
            inputParams.imageURI
        );

        emit EditionCreated(msg.sender, editionAddress);
    }

    function _deployProxy(
        address implementation,
        address creator,
        uint salt
    ) public returns (address _contractAddress) {
        bytes memory code = _creationCode(implementation, creator, salt);
        _contractAddress = Create2.computeAddress(
            bytes32(salt),
            keccak256(code)
        );
        if (_contractAddress.code.length != 0) return _contractAddress;

        _contractAddress = Create2.deploy(0, bytes32(salt), code);
    }

    function _creationCode(
        address implementation_,
        address _creator,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, _creator)
            );
    }
}
