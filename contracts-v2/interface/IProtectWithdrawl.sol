interface IProtectWithdrawl {
    function setup(
        address _creator,
        address _safe,
        address _creatorNullifier,
        address _module
    ) external;
}
