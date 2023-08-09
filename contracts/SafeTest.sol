pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/Create2.sol";

contract SafeTest {
    address public immutable i_safeImplementation;
    address public immutable i_moduleImplementation;
    bytes4 public constant SET_GUARD_METHOD_ID =
        bytes4(keccak256("setGuard(address)"));
    bytes4 public constant SETUP_MODULES_METHOD_ID =
        bytes4(keccak256("setupModules(address,bytes)"));
    bytes4 public constant ENABLE_MODULE_METHOD_ID =
        bytes4(keccak256("enableModule(address)"));
    bytes4 public constant SETUP_MODULE_METHOD_ID =
        bytes4(keccak256("setup(address,address,bytes32)"));
    bytes4 public constant SETUP_SAFE_METHOD_ID =
        bytes4(
            keccak256(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)"
            )
        );
    bytes4 public constant EXECTRANSACTION_METHOD_ID =
        bytes4(
            keccak256(
                "execTransaction(address,uint256,bytes,Enum.Operation,uint256,uint256,uint256,address,address,bytes)"
            )
        );

    constructor(address safeImplementation, address moduleImplementation) {
        i_safeImplementation = safeImplementation;
        i_moduleImplementation = moduleImplementation;
    }

    function deploySafe(uint salt, bytes calldata signature) public {
        address safeAddress = _deployProxy(
            i_safeImplementation,
            msg.sender,
            salt
        );
        address moduleAddress = _deployProxy(
            i_moduleImplementation,
            msg.sender,
            salt
        );

        bytes memory setupData = abi.encodeWithSelector(
            SETUP_MODULE_METHOD_ID,
            msg.sender,
            moduleAddress,
            bytes32(0)
        );

        bytes memory enableModuleData = abi.encodeWithSelector(
            ENABLE_MODULE_METHOD_ID,
            moduleAddress
        );

        safeAddress.call(
            abi.encodeWithSelector(
                SETUP_SAFE_METHOD_ID,
                [msg.sender],
                1,
                moduleAddress,
                setupData,
                address(0),
                address(0),
                0,
                address(0)
            )
        );

        // safeAddress.call(
        //     abi.encodeWithSelector(
        //         EXECTRANSACTION_METHOD_ID,
        //         safeAddress,
        //         0,
        //         enableModuleData,
        //         0,
        //         0,
        //         0,
        //         0,
        //         address(0),
        //         payable(address(0)),

        //     )
        // );
        // safeAddress.call();
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
