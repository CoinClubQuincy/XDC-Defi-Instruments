// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./Mocks.sol";
import "../../contracts/Defi-Tools/Asset.sol";
import "../../contracts/Defi-Tools/Contract.sol";
import "../../contracts/Defi-Tools/DocToken.sol";
import "../../contracts/Defi-Tools/DelegatedExecutor.sol";
import "../../contracts/Defi-Tools/GeneralDeployer.sol";
import "../../contracts/Defi-Tools/Macro_Contracts.sol";
import "../../contracts/Defi-Tools/Micro_Contracts.sol";

contract AgreementTest is Test {
    address partyA = makeAddr("partyA");
    address partyB = makeAddr("partyB");
    address witnessA = makeAddr("witnessA");
    address witnessB = makeAddr("witnessB");
    Contract agreement;

    function setUp() public {
        agreement = new Contract("hash-1", "Agreement", "uri", partyA);
        vm.startPrank(partyA);
        agreement.safeTransferFrom(partyA, partyB, 1, 1, "");
        agreement.safeTransferFrom(partyA, witnessA, 2, 1, "");
        agreement.safeTransferFrom(partyA, witnessB, 3, 1, "");
        vm.stopPrank();
    }

    function signAll() internal {
        address[4] memory signers = [partyA, partyB, witnessA, witnessB];
        for (uint i = 0; i < signers.length; i++) {
            vm.prank(signers[i]);
            agreement.sign_proposal();
        }
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
        vm.expectRevert("you do not hold the Party B token");
        agreement.counter_proposal_B("hash-2");
        vm.prank(witnessA);
        vm.expectRevert("you do not hold the Party A token");
        agreement.counter_proposal_A("hash-2");
    }

    function test_EachRoleSignsAndTheLastCompletesIt() public {
        vm.prank(partyA);
        (bool ok, string memory message) = agreement.sign_proposal();
        assertTrue(ok);
        assertEq(message, "Party A has signed Document");
        assertEq(agreement.PartyASignature(), partyA);
        assertFalse(agreement.contractComplete());

        vm.prank(partyB);
        agreement.sign_proposal();
        vm.prank(witnessA);
        agreement.sign_proposal();
        assertFalse(agreement.contractComplete());

        vm.prank(witnessB);
        (ok, message) = agreement.sign_proposal();
        assertEq(message, "Contract completed");
        assertTrue(agreement.contractComplete());
    }

    function test_NobodySignsTwice() public {
        vm.startPrank(partyA);
        agreement.sign_proposal();
        vm.expectRevert("you have already signed");
        agreement.sign_proposal();
        vm.stopPrank();
    }

    function test_OneAddressCannotHoldTwoSigningRoles() public {
        Contract solo = new Contract("hash", "Agreement", "uri", partyA);
        vm.startPrank(partyA);
        solo.sign_proposal();
        vm.expectRevert("you have already signed");
        solo.sign_proposal();
        vm.stopPrank();
    }

    function test_StrangersCannotSign() public {
        vm.prank(makeAddr("stranger"));
        vm.expectRevert("you hold no unsigned role");
        agreement.sign_proposal();
    }

    function test_ACounterProposalClearsSignatures() public {
        vm.prank(partyA);
        agreement.sign_proposal();
        vm.prank(witnessA);
        agreement.sign_proposal();

        vm.prank(partyB);
        agreement.counter_proposal_B("hash-2");
        assertEq(agreement.PartyASignature(), address(0));
        assertEq(agreement.WitnessASignature(), address(0));

        signAll();
        assertTrue(agreement.contractComplete());
    }

    function test_ACompletedAgreementIsFinal() public {
        signAll();
        vm.prank(partyA);
        vm.expectRevert("contract has already been signed");
        agreement.counter_proposal_A("hash-2");
        vm.prank(partyA);
        vm.expectRevert("contract has already been signed");
        agreement.sign_proposal();
    }

    function test_DocumentHashIsRequired() public {
        vm.expectRevert("Document hash cannot be empty");
        new Contract("", "Agreement", "uri", partyA);
        vm.prank(partyA);
        vm.expectRevert("Document hash cannot be empty");
        agreement.counter_proposal_A("");
    }

    function test_DeployerGivesTheTokensToTheCaller() public {
        ContractDeployer deployer = new ContractDeployer();
        vm.prank(partyA);
        Contract deployed = Contract(payable(deployer.deployContract("hash", "Agreement", "uri")));
        assertEq(deployed.balanceOf(partyA, 0), 1);
        assertEq(deployed.balanceOf(partyA, 3), 1);
        assertTrue(deployed.verify("hash"));
    }
}

contract AssetTest is Test {
    address broker = makeAddr("broker");
    address user = makeAddr("user");
    address other = makeAddr("other");
    Asset asset;

    function setUp() public {
        vm.prank(broker);
        asset = new Asset("uri");
        vm.prank(broker);
        asset.AddToken("Gold", "One ounce", "gold.png", "Commodity");
    }

    function test_AddTokenStoresDetailsAndMintsToTheBroker() public {
        assertEq(asset.totalCoins(), 1);
        assertEq(asset.balanceOf(broker, 0), 1);
        (string memory name,,, string memory assetType) = asset.viewToken(0);
        assertEq(name, "Gold");
        assertEq(assetType, "Commodity");
    }

    function test_BrokerCanMoveAnAssetFromAnAbandonedAccount() public {
        vm.prank(broker);
        asset.safeTransferFrom(broker, user, 0, 1, "");
        vm.prank(broker);
        assertTrue(asset.moveAsset(0, user, other, 1));
        assertEq(asset.balanceOf(other, 0), 1);
        assertEq(asset.balanceOf(user, 0), 0);
    }

    function test_MoveChecksTheAmountAndToken() public {
        uint key = asset.handlerToken();
        vm.startPrank(broker);
        vm.expectRevert("Insufficient balance");
        asset.moveAsset(0, broker, user, 2);
        vm.expectRevert("Token does not exist");
        asset.moveAsset(key, broker, user, 1);
        vm.stopPrank();
    }

    function test_BrokerCanDestroyAnAsset() public {
        vm.prank(broker);
        asset.destroyAsset(0, broker);
        assertEq(asset.balanceOf(broker, 0), 0);
    }

    function test_HandlerKeyCannotBeDestroyed() public {
        uint token = asset.handlerToken();
        vm.prank(broker);
        vm.expectRevert("Token does not exist");
        asset.destroyAsset(token, broker);
    }

    function test_OnlyTheBrokerActs() public {
        vm.startPrank(user);
        vm.expectRevert("user does not hold handlerToken");
        asset.AddToken("Gold", "a", "b", "c");
        vm.expectRevert("user does not hold handlerToken");
        asset.moveAsset(0, broker, user, 1);
        vm.expectRevert("user does not hold handlerToken");
        asset.destroyAsset(0, broker);
        vm.stopPrank();
    }

    function test_AssetRefusesMoneyItCouldNeverReturn() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool sent,) = address(asset).call{value: 1 ether}("");
        assertFalse(sent);
    }
}

contract DocumentTest is Test {
    address owner = makeAddr("owner");
    Document doc;

    function setUp() public {
        vm.prank(owner);
        doc = new Document("uri", 2);
    }

    function test_FirstDocumentIsNotAHandlerKey() public {
        address holder = makeAddr("holder");
        vm.startPrank(owner);
        doc.createDoc("Deed", "hash", "A deed");
        doc.safeTransferFrom(owner, holder, 0, 1, "");
        vm.stopPrank();
        vm.prank(holder);
        vm.expectRevert("user does not hold handler token");
        doc.createDoc("Forged", "hash", "A forged deed");
    }

    function test_DocumentsAreListed() public {
        vm.startPrank(owner);
        doc.createDoc("One", "hash1", "First");
        doc.createDoc("Two", "hash2", "Second");
        vm.stopPrank();
        assertEq(doc.totalDocs(), 2);
        assertEq(doc.viewAllDocs()[1].name, "Two");
        assertEq(doc.viewToken(0).docHash, "hash1");
        vm.expectRevert("Invalid token");
        doc.viewToken(2);
    }

    function test_DocumentNeedsAllItsFields() public {
        vm.startPrank(owner);
        vm.expectRevert("Name cannot be empty");
        doc.createDoc("", "hash", "x");
        vm.expectRevert("Document hash cannot be empty");
        doc.createDoc("x", "", "x");
        vm.expectRevert("Description cannot be empty");
        doc.createDoc("x", "hash", "");
        vm.stopPrank();
    }

    function test_NeedsAHandler() public {
        vm.expectRevert("at least one handler is required");
        new Document("uri", 0);
    }
}

contract DelegateExecutorTest is Test {
    address user = makeAddr("user");
    address master = makeAddr("master");
    address payee = makeAddr("payee");
    address stranger = makeAddr("stranger");
    DelegateExecutor executor;

    function setUp() public {
        vm.prank(user);
        executor = new DelegateExecutor("uri", 3, master);
        vm.deal(address(executor), 5 ether);
    }

    function test_KeysAreSplit() public {
        assertEq(executor.balanceOf(user, executor.handlerToken()), 1);
        assertEq(executor.balanceOf(master, executor.handlerToken()), 2);
    }

    function test_NeedsThreeKeys() public {
        vm.expectRevert("3 key minimum");
        new DelegateExecutor("uri", 2, master);
    }

    function test_SendsMoney() public {
        vm.prank(user);
        executor.Send(payee, 1 ether);
        assertEq(payee.balance, 1 ether);
    }

    function test_ReportsAFailedPayment() public {
        RefusesMoney refuser = new RefusesMoney();
        vm.prank(user);
        vm.expectRevert("Payment failed");
        executor.Send(address(refuser), 1 ether);
    }

    function test_SendsXRC20() public {
        MockCoin coin = new MockCoin();
        coin.mint(address(executor), 100);
        vm.prank(master);
        executor.SendXRC20(payee, 40, address(coin));
        assertEq(coin.balanceOf(payee), 40);
    }

    function test_SendsXRC1155() public {
        MockToken token = new MockToken();
        token.mint(address(executor), 7, 5);
        uint[] memory amounts = new uint[](1);
        uint[] memory ids = new uint[](1);
        amounts[0] = 3;
        ids[0] = 7;
        vm.prank(user);
        executor.SendXRC1155(payee, address(token), amounts, ids, "");
        assertEq(token.balanceOf(payee, 7), 3);
    }

    function test_XRC1155ChecksItsInput() public {
        MockToken token = new MockToken();
        uint[] memory none = new uint[](0);
        uint[] memory one = new uint[](1);
        vm.startPrank(user);
        vm.expectRevert("Nothing to send");
        executor.SendXRC1155(payee, address(token), none, none, "");
        vm.expectRevert("Amount must be greater than 0");
        executor.SendXRC1155(payee, address(token), one, one, "");
        vm.stopPrank();
    }

    function test_ExecuteCallCallsAContract() public {
        Counter counter = new Counter();
        vm.prank(user);
        executor.executeCall(address(counter), 1 ether, abi.encodeCall(Counter.increase, ()));
        assertEq(counter.count(), 1);
        assertEq(counter.paid(), 1 ether);
    }

    function test_ExecuteCallReportsFailure() public {
        Counter counter = new Counter();
        vm.startPrank(user);
        vm.expectRevert("Call failed");
        executor.executeCall(address(counter), 0, hex"12345678");
        vm.expectRevert("Target is not a contract");
        executor.executeCall(payee, 0, "");
        vm.stopPrank();
    }

    function test_StrangersCannotAct() public {
        vm.startPrank(stranger);
        vm.expectRevert("user does not hold handler token");
        executor.Send(stranger, 1 ether);
        vm.expectRevert("user does not hold handler token");
        executor.SendXRC20(stranger, 1, address(1));
        vm.expectRevert("user does not hold handler token");
        executor.SendXRC1155(stranger, address(1), new uint[](0), new uint[](0), "");
        vm.expectRevert("user does not hold handler token");
        executor.executeCall(address(1), 1 ether, "");
        vm.stopPrank();
        assertEq(address(executor).balance, 5 ether);
    }
}

contract MacroMicroTest is Test {
    address owner = makeAddr("owner");
    address stranger = makeAddr("stranger");
    MACRO macroContract;
    MICRO micro;

    function setUp() public {
        vm.startPrank(owner);
        macroContract = new MACRO(1, "uri");
        micro = new MICRO("Micro", "Parameters", 1, "uri");
        vm.stopPrank();
    }

    function schema(string memory value) internal pure returns (string[] memory list) {
        list = new string[](1);
        list[0] = value;
    }

    function test_MacroKeepsEveryVersion() public {
        vm.startPrank(owner);
        macroContract.initialize(schema("v1"));
        assertEq(macroContract.modifySchema(schema("v2")), 2);
        vm.stopPrank();

        assertEq(macroContract.viewCurrentSchema()[0], "v2");
        MACRO.History[] memory history = macroContract.viewAllSchemaHistory();
        assertEq(history.length, 2);
        assertEq(history[0].schema[0], "v1");
    }

    function test_MacroInitializesOnce() public {
        vm.startPrank(owner);
        macroContract.initialize(schema("v1"));
        vm.expectRevert("Contract already initialized");
        macroContract.initialize(schema("v2"));
        vm.stopPrank();
    }

    function test_MacroChecksItsInputAndOrder() public {
        vm.startPrank(owner);
        vm.expectRevert("Contract not initialized");
        macroContract.modifySchema(schema("v1"));
        vm.expectRevert("Schema must be defined");
        macroContract.initialize(schema(""));
        vm.expectRevert("Schema must be defined");
        macroContract.initialize(new string[](0));
        vm.stopPrank();
        vm.expectRevert("Contract not initialized");
        macroContract.viewCurrentSchema();
    }

    function test_MacroNeedsAKey() public {
        vm.prank(stranger);
        vm.expectRevert("user does not hold handler token");
        macroContract.initialize(schema("v1"));
    }

    function test_MicroStoresAndChangesParameters() public {
        vm.startPrank(owner);
        micro.initialize(10, 20);
        assertEq(micro.view_single_parameter("transacted_funds_rate"), 10);
        micro.set_single_parameter("transacted_funds_rate", 11);
        micro.set_single_parameter("liquid_invoice_intrest_rate", 21);
        vm.stopPrank();

        MICRO.Parameters memory all = micro.view_all_parameters();
        assertEq(all.transacted_funds_rate, 11);
        assertEq(all.liquid_invoice_intrest_rate, 21);
    }

    function test_MicroRefusesUnknownParametersAndRepeatSetup() public {
        vm.startPrank(owner);
        vm.expectRevert("Not initialized");
        micro.set_single_parameter("transacted_funds_rate", 1);
        micro.initialize(1, 2);
        vm.expectRevert("Already initialized");
        micro.initialize(3, 4);
        vm.expectRevert("Parameter not found");
        micro.set_single_parameter("nothing", 1);
        vm.expectRevert("Parameter not found");
        micro.view_single_parameter("nothing");
        vm.stopPrank();
    }

    function test_MicroNeedsAKey() public {
        vm.startPrank(stranger);
        vm.expectRevert("user does not hold handler token");
        micro.initialize(1, 2);
        vm.expectRevert("user does not hold handler token");
        micro.set_single_parameter("transacted_funds_rate", 1);
        vm.stopPrank();
    }

    function test_DeployerRefusesFailedDeployments() public {
        ManagerDeployer deployer = new ManagerDeployer("Open", "Open", false, "");
        vm.expectRevert("deployment failed");
        deployer.createManager("Bad", "Bad code", hex"fe", "");
        address made = deployer.createManager("Good", "Good code", type(Counter).creationCode, "");
        assertEq(deployer.viewAllContracts()[0].contractAddress, made);
    }

    function test_SingleContractDeployerRefusesOtherCode() public {
        ManagerDeployer deployer = new ManagerDeployer("One", "One", true, type(Counter).creationCode);
        vm.expectRevert("this deployer can only deploy a single contract type");
        deployer.createManager("Other", "Other code", hex"00", "");
        deployer.createManager("Same", "Same code", type(Counter).creationCode, "");
        assertEq(deployer.totalContracts(), 1);
    }
}
