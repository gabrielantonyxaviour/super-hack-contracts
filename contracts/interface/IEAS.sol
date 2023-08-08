interface IEAS {
    struct AttestationRequestData {
        address recipient; // The recipient of the attestation.
        uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
        bool revocable; // Whether the attestation is revocable.
        bytes32 refUID; // The UID of the related attestation.
        bytes data; // Custom attestation data.
        uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
    }
    struct AttestationRequest {
        bytes32 schema; // The unique identifier of the schema.
        AttestationRequestData data; // The arguments of the attestation request.
    }

    function attest(
        AttestationRequest calldata request
    ) external payable returns (bytes32);
}
