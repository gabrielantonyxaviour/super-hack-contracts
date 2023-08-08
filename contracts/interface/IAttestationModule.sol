interface IAttestationModule {
    function getTotalMintFee() external view returns (uint256);

    function setup(address nftAddress) external;
}
