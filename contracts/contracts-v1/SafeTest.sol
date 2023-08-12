pragma solidity ^0.8.19;
import "@openzeppelin/contracts/utils/Create2.sol";
import "./interface/ISafeProxyFactory.sol";

contract SafeTest {
    ISafeProxyFactory public immutable i_safeProxyFactory;
    address public immutable i_moduleImplementation;
    address public immutable i_safeImplementation;
    address public immutable i_guardImplementation;
    bytes4 public constant SET_GUARD_METHOD_ID =
        bytes4(keccak256("setGuard(address)"));
    
    bytes4 public constant ENABLE_MODULE_METHOD_ID =
        bytes4(keccak256("enableModule(address)"));
    
    bytes4 public constant EXECTRANSACTION_METHOD_ID =
        bytes4(
            keccak256(
                "execTransaction(address,uint256,bytes,Enum.Operation,uint256,uint256,uint256,address,address,bytes)"
            )
        );

    constructor(
        ISafeProxyFactory safeProxyFactory,
        address safeImplementation,
        address moduleImplementation,
        address guardImplementation
    ) {
        i_safeProxyFactory = safeProxyFactory;
        i_safeImplementation=safeImplementation;
        i_moduleImplementation = moduleImplementation;
        i_guardImplementation=guardImplementation;
    }

    event SafeSetupCompleted(
        address indexed creator,
        address indexed safeAddress,
        address indexed moduleAddress,
        address guardAddress
    );
    function deploySafe(uint salt, bytes[2] calldata signatures) public {

        // Deploy Module
        address moduleAddress = _deployProxy(
            i_moduleImplementation,
            msg.sender,
            salt
        );
         address guardAddress = _deployProxy(
            i_guardImplementation,
            msg.sender,
            salt
        );
        // Create Safe and setupModules
        GnosisSafeProxy safe=_deploySafe(moduleAddress,salt);
        
        // Enable Module
        _enableModule(address(safe), guardAddress, signatures[0]);

        // Set Guard
        _setGuard(address(safe), guardAddress, signatures[1]);

        emit SafeSetupCompleted(msg.sender, address(safe), moduleAddress, guardAddress);
    }

    function _deployProxy(
        address implementation,
        address creator,
        uint salt
    ) internal returns (address _contractAddress) {
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

    function _enableModule(address safe,address guardAddress,bytes calldata signatures) internal {
        bytes memory enableModuleData = abi.encodeWithSelector(
            ENABLE_MODULE_METHOD_ID,
            guardAddress
        );
        (bool success,)=address(safe).call(
            abi.encodeWithSelector(
                EXECTRANSACTION_METHOD_ID,
                address(safe),
                0,
                enableModuleData,
                0,
                0,
                0,
                0,
                address(0),
                address(0),
                signatures
            )
        );
        require(success,"Enable Module Failed");
    }
        bytes4 public constant SETUP_MODULES_METHOD_ID =
        bytes4(keccak256("setupModules(address,bytes)"));
    bytes4 public constant SETUP_SAFE_METHOD_ID =
        bytes4(
            keccak256(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)"
            )
        );
    function _deploySafe(address moduleAddress,uint salt) internal returns(GnosisSafeProxy){
            bytes memory setupModulesData = abi.encodeWithSelector(
                SETUP_MODULES_METHOD_ID,
                moduleAddress,
                ""
            );
    
            return i_safeProxyFactory.createProxyWithNonce(i_safeImplementation,abi.encodeWithSelector(
                    SETUP_SAFE_METHOD_ID,
                    [msg.sender],
                    1,
                    moduleAddress,
                    setupModulesData,
                    address(0),
                    address(0),
                    0,
                    address(0)
                ),salt);
        }
        function _setGuard(address safe,address guardAddress,bytes calldata signature) internal {
            bytes memory setGuardData=abi.encodeWithSelector(SET_GUARD_METHOD_ID,guardAddress);
            (bool success,)=address(safe).call(
                abi.encodeWithSelector(
                    EXECTRANSACTION_METHOD_ID,
                    address(safe),
                    0,
                    setGuardData,
                    0,
                    0,
                    0,
                    0,
                    address(0),
                    address(0),
                    signature
                )
            );
            require(success,"Set Guard Failed");
        }
}
