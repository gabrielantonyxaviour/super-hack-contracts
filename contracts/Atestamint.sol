pragma solidity ^0.8.7;

import "./interface/IZoraFactory.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Atestamint {
    IZoraFactory public immutable i_zoraNftFactory;
    address public immutable i_safeImplementation;
    address public immutable i_guardImplementation;
    address public immutable i_moduleImplementation;

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
        string memory name,
        string memory symbol,
        uint64 editionSize,
        uint16 royaltyBPS,
        IERC721Drop.SalesConfiguration memory saleConfig,
        string memory metadataURIBase,
        string memory metadataContractURI,
        uint salt
    ) public {
        address guardAddress = _deployProxy(
            i_guardImplementation,
            msg.sender,
            salt
        );

        address moduleAddress = _deployProxy(
            i_moduleImplementation,
            msg.sender,
            salt
        );

        address safeAddress = _deployProxy(
            i_safeImplementation,
            msg.sender,
            salt
        );
        bytes4 methodId = bytes4(keccak256("setup(address,address)"));
        (bool success, ) = guardAddress.call(
            abi.encodeWithSelector(methodId, safeAddress, moduleAddress)
        );
        if (!success) {
            revert("Create Failed");
        }
        address dropAddress = i_zoraNftFactory.createDrop(
            name,
            symbol,
            safeAddress,
            editionSize,
            royaltyBPS,
            payable(safeAddress),
            saleConfig,
            metadataURIBase,
            metadataContractURI
        );

        emit DropCreated(msg.sender, dropAddress);
    }

    function createEditionCollection(
        string memory name,
        string memory symbol,
        uint64 editionSize,
        uint16 royaltyBPS,
        IERC721Drop.SalesConfiguration memory saleConfig,
        string memory description,
        string memory animationURI,
        string memory imageURI,
        uint salt
    ) public {
        address guardAddress = _deployProxy(
            i_guardImplementation,
            msg.sender,
            salt
        );

        address moduleAddress = _deployProxy(
            i_moduleImplementation,
            msg.sender,
            salt
        );

        address safeAddress = _deployProxy(
            i_safeImplementation,
            msg.sender,
            salt
        );
        bytes4 methodId = bytes4(keccak256("setup(address,address)"));
        (bool success, ) = guardAddress.call(
            abi.encodeWithSelector(methodId, safeAddress, moduleAddress)
        );
        if (!success) {
            revert("Create Failed");
        }
        address editionAddress = i_zoraNftFactory.createEdition(
            name,
            symbol,
            editionSize,
            royaltyBPS,
            payable(safeAddress),
            safeAddress,
            saleConfig,
            description,
            animationURI,
            imageURI
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
