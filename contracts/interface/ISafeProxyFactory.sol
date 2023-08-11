pragma solidity ^0.8.10;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";

interface ISafeProxyFactory {
    function createProxyWithNonce(
        address _implementation,
        bytes memory _initializer,
        uint256 saltNonce
    ) external returns (GnosisSafeProxy proxy);
}
