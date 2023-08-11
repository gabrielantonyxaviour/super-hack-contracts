pragma solidity ^0.8.7;

import "../interface/IGuard.sol";
import "../utils/Enum.sol";
import "../interface/IAttestationModule.sol";
import "../utils/Bytecode.sol";

contract ProtectWithdrawl is IGuard {
    bool public initialized;

    address public immutable i_atestamint;
    address private safe;
    address private attestationModule;

    constructor(address atestamint) {
        i_atestamint=atestamint;
        initialized = false;
    }

    modifier onlyAtestamint() {
        require(msg.sender == i_atestamint, "Inavlid sender");
        _;
    }
    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
    }

    event GuardInitialized();
    event GuardCheckComplete();

    function setup(
        address _safe,
        address _module
    ) public onlyOnce onlyAtestamint {
        safe = _safe;
        attestationModule = _module;
        initialized = true;
        emit GuardInitialized();
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external {
        revert("Not allowed");
    }

    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        address module
    ) external returns (bytes32 moduleTxHash) {
        require(to == getCreator(), "Not allowed");
        require(attestationModule == module, "Invalid module");
        require(
            value == IAttestationModule(module).getTotalMintFee(),
            "Invalid value"
        );
        require(operation == Enum.Operation.Call, "Invalid operation");
        moduleTxHash = keccak256(
            abi.encodePacked(to, value, data, operation, module)
        );
        emit GuardCheckComplete();
    }

    function checkAfterExecution(bytes32 hash, bool success) external {
        require(safe.balance == 0, "Balance not 0");
        require(success, "Transaction failed");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {
        return interfaceId == type(IGuard).interfaceId;
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
