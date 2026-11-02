// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../contracts/Defi-Tools/Contract.sol";

/// Tests whose names start with test_KnownIssue pin current behaviour that is a defect.
contract AgreementTest is Test {
    address partyA = makeAddr("partyA");
    address partyB = makeAddr("partyB");
    Contract agreement;

    function setUp() public {
        vm.startPrank(partyA);
        agreement = new Contract("hash-1", "Agreement", "uri");
        agreement.safeTransferFrom(partyA, partyB, 1, 1, "");
        vm.stopPrank();
    }

    function test_VerifyMatchesOnlyTheStoredHash() public {
        assertTrue(agreement.verify("hash-1"));
        vm.expectRevert("Hashes do not match");
        agreement.verify("other");
    }

    function test_CounterProposalReplacesTheHashAndCounts() public {
        vm.prank(partyB);
        agreement.counter_proposal_B("hash-2");
        assertTrue(agreement.verify("hash-2"));
        assertEq(agreement.total_Counter_Proposals(), 1);
    }

    function test_OnlyTheMatchingPartyCanCounter() public {
        vm.prank(partyA);
        vm.expectRevert();
        agreement.counter_proposal_B("hash-2");
    }

    function test_KnownIssue_NobodyCanSignBecauseSigningRequiresBothSignatures() public {
        vm.prank(partyA);
        vm.expectRevert();
        agreement.sign_proposal();
    }

    function test_KnownIssue_ContractDeployerAlwaysReverts() public {
        ContractDeployer deployer = new ContractDeployer();
        vm.prank(partyA);
        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        deployer.deployContract("hash", "Agreement", "uri");
    }
}
