// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.19;

import {Test} from "@forge-std/Test.sol";
import {console2} from "../../lib/forge-std/src/console2.sol";
import {SyndicateTokenV1} from "../../src/SyndicateTokenV1.sol";
import {SyndicateDeployerV1} from "../../src/SyndicateDeployerV1.sol";
import {ISyndicateDeployerV1} from "../../src/interfaces/ISyndicateDeployerV1.sol";
import {SyndicateRegistry} from "../../src/SyndicateRegistry.sol";
import {ISyndicateRegistry} from "../../src/interfaces/ISyndicateRegistry.sol";
import {ERC721} from "../../lib/openzepplin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "../../lib/openzepplin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC6551Registry} from "../../lib/tokenbound/lib/erc6551/src/ERC6551Registry.sol";
import {IERC6551Registry} from "../../lib/tokenbound/lib/erc6551/src/interfaces/IERC6551Registry.sol";
import {ERC6551Account} from "../../lib/tokenbound/src/abstract/ERC6551Account.sol";
import {IERC6551Account} from "../../lib/tokenbound/lib/erc6551/src/interfaces/IERC6551Account.sol";
import {IAzimuth} from "../../src/interfaces/IAzimuth.sol";

contract SyndicateEcosystemTest is Test {
    IERC6551Registry public tbaRegistry;
    IERC721 public eclipticContract;
    IERC6551Account public tbaImplementation;
    IAzimuth public azimuthContract;

    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    SyndicateTokenV1 public launchedSyndicate;

    address public registryAddress;
    address public deployerAddress;
    address public permissionedContract;

    address public owner;
    address public alice;
    address public bob;
    address public syndicateOwner;
    address public tbaAddressForSamzod;

    uint256 public constant DEFAULT_MINT = 1000000000000000000000000; // 1M with 18 decimals
    uint256 public constant DEFAULT_MAXSUPPLY = 21000000000000000000000000; // 21M with 18 decimals
    uint256 public constant FEE = 500; // in basis points (500 = 5%)
    bytes32 public constant SALT = bytes32(0);
    address public constant NULL_IMPLEMENTATION = address(0);

    uint256 public forkId;

    function setUp() public {
        string memory SEPOLIA_RPC = vm.envString("SEPOLIA_RPC_URL");
        forkId = vm.createSelectFork(SEPOLIA_RPC);

        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        azimuthContract = IAzimuth(vm.envAddress("SEPOLIA_AZIMUTH_CONTRACT"));
        eclipticContract = IERC721(vm.envAddress("SEPOLIA_ECLIPTIC_CONTRACT"));

        tbaRegistry = IERC6551Registry(vm.envAddress("SEPOLIA_TBA_REGISTRY"));
        tbaImplementation = IERC6551Account(
            payable(vm.envAddress("SEPOLIA_TBA_IMPLEMENTATION"))
        );

        syndicateOwner = vm.envAddress("SEPOLIA_PUBLIC_KEY_0");

        vm.startPrank(owner);
        registry = new SyndicateRegistry(address(azimuthContract));
        registryAddress = address(registry);

        deployerV1 = new SyndicateDeployerV1(registryAddress, FEE);
        deployerAddress = address(deployerV1);

        vm.stopPrank();

        // verify fork is working
        assertTrue(
            address(tbaRegistry).code.length > 0,
            "TBA Registry not deployed"
        );
        assertTrue(
            address(eclipticContract).code.length > 0,
            "Ecliptic not deployed"
        );
        assertTrue(
            address(azimuthContract).code.length > 0,
            "Azimuth not deployed"
        );
    }

    // Helper functions
    //// Registry and Deployer are live
    function _registerDeployer() public {
        vm.startPrank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        // Deactivate beta mode for default test state
        deployerV1.toggleBetaMode(false);
        deployerV1.addApprovedTbaImplementation(address(tbaImplementation));

        vm.stopPrank();
    }

    //// launch a syndicate token

    function _launchSyndicateToken() public returns (address) {
        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        vm.prank(tbaAddressForSamzod);
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            DEFAULT_MAXSUPPLY,
            1024,
            "~samzod Test Syndicate",
            "~SAMZOD"
        );
        console2.log(
            "Syndicate Contract Launched at: ",
            address(syndicateTokenV1)
        );
        launchedSyndicate = SyndicateTokenV1(payable(syndicateTokenV1));
        console2.log("syndicateOwner: ", launchedSyndicate.getOwner());
        console2.log("initialSupply: ", launchedSyndicate.totalSupply());
        console2.log("maxSupply: ", launchedSyndicate.getMaxSupply());
        console2.log("azimiuthPoint: ", launchedSyndicate.getAzimuthPoint());
        console2.log("name: ", launchedSyndicate.name());
        console2.log("symbol: ", launchedSyndicate.symbol());

        assertTrue(
            address(syndicateTokenV1).code.length > 0,
            "Syndicate Token not deployed"
        );

        return address(launchedSyndicate);
    }

    //// get TBA address
    function _getTbaAddress(
        address implementation,
        uint256 tokenId
    ) internal view returns (address) {
        return
            tbaRegistry.account(
                implementation,
                SALT,
                block.chainid,
                registryAddress,
                tokenId
            );
    }

    // Core Tests
    //// Registry Tests
    function test_InitialDeploymentOwnership() public view {
        assertEq(
            owner,
            registry.getOwner(),
            "Owner should be the deployment address"
        );
        assertEq(
            registry.getOwner(),
            deployerV1.getOwner(),
            "Owner should be the registry contract owner"
        );
    }

    function test_ProposeNewRegistryOwnerByOwner() public {
        vm.prank(owner);
        registry.proposeNewOwner(bob);
        assertEq(
            bob,
            registry.getPendingOwner(),
            "Pending owner should be proposed owner"
        );
    }

    function test_AcceptRegistryOwnershipByPendingOwner() public {
        vm.prank(owner);
        registry.proposeNewOwner(bob);
        assertEq(
            bob,
            registry.getPendingOwner(),
            "Pending owner should be proposed owner"
        );
        vm.prank(bob);
        registry.acceptOwnership();
        assertEq(
            bob,
            registry.getOwner(),
            "Previously pending owner should be owner"
        );
    }

    function test_RejectRegistryOwnershipByPendingOwner() public {
        vm.prank(owner);
        registry.proposeNewOwner(bob);
        vm.prank(bob);
        registry.rejectOwnership();
        assertEq(
            owner,
            registry.getOwner(),
            "Old owner should still be the owner"
        );
    }

    function test_NullifyRegistryOwnershipProposalByOwner() public {
        vm.startPrank(owner);
        registry.proposeNewOwner(bob);
        registry.nullifyProposal();
        assertEq(
            owner,
            registry.getOwner(),
            "Old Owner should still be the owner"
        );
        assertEq(
            address(0),
            registry.getPendingOwner(),
            "Pending owner should be reset to the null address"
        );
    }

    function test_RevertOnNullifyRegistryOwnershipProposalByNotOwner() public {
        vm.prank(owner);
        registry.proposeNewOwner(bob);
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        registry.nullifyProposal();
    }

    function test_RenounceRegistryOwnershipByOwner() public {
        vm.prank(owner);
        registry.renounceOwnership();
        assertEq(
            address(0),
            registry.getOwner(),
            "Owner address should be the null address"
        );
    }

    function test_RevertOnRenounceRegistryOwnershipByNotOwner() public {
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        registry.renounceOwnership();
    }

    function test_RegisterNewDeployerByOwner() public {
        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerRegistered(
            address(deployerV1),
            1,
            true
        );

        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        assertEq(
            true,
            registry.isRegisteredDeployer(address(deployerV1)),
            "Is not registered deployment"
        );
    }

    function test_RevertOnRegisterNewDeployerByNotOwner() public {
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    function test_RegisterSecondDeployerByOwner() public {
        _registerDeployer();
        address deployerV2 = makeAddr("deployerV2");
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV2),
                deployerVersion: 2,
                isActive: true
            })
        );
    }

    function test_RevertOnRegisterSecondDeployerByNotOwner() public {
        _registerDeployer();
        address deployerV2 = makeAddr("deployerV2");
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV2),
                deployerVersion: 2,
                isActive: true
            })
        );
    }

    function test_RevertOnDuplicateRegisterDeployerByOwner() public {
        _registerDeployer();
        vm.prank(owner);
        vm.expectRevert("Deployer is already registered");
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    function testFuzz_RevertOnRegisterNewDeployerByNotOwner(
        address[] calldata randomCallers
    ) public {
        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert("Unauthorized: Only registry owner");
            registry.registerDeployer(
                ISyndicateRegistry.SyndicateDeployerData({
                    deployerAddress: address(deployerV1),
                    deployerVersion: 1,
                    isActive: true
                })
            );
        }
    }

    function testFuzz_RevertOnRegisterSyndicateTokenInRegistryByNonDeployer(
        address[] calldata randomCallers
    ) public {
        address tokenOwner = makeAddr("tokenOwner");
        address tokenContract = makeAddr("tokenContract");
        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry
            .Syndicate({
                syndicateOwner: tokenOwner,
                syndicateContract: tokenContract,
                syndicateDeployer: address(deployerV1),
                syndicateLaunchTime: block.number,
                azimuthPoint: 1
            });
        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert("Unauthorized: Only registered deployers");
            registry.registerSyndicate(syndicate);
        }
    }

    function testFuzz_RevertOnUpdateSyndicateTokenOwnerRegistryByNonDeployer(
        address[] calldata randomCallers
    ) public {
        address newTokenOwner = makeAddr("newTokenOwner");
        address tokenContract = makeAddr("tokenContract");
        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert("Unauthorized: Only registered deployers");
            registry.updateSyndicateOwnerRegistration(
                tokenContract,
                newTokenOwner
            );
        }
    }

    function test_RevertOnRegisterNewSyndicateByInactiveDeployer() public {
        _registerDeployer();
        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        assertEq(
            registry.isActiveDeployer(address(deployerV1)),
            false,
            "Deployer should be inactive at this stage"
        );

        address tokenOwner = makeAddr("tokenOwner");
        address tokenContract = makeAddr("tokenContract");
        ISyndicateRegistry.Syndicate memory syndicate = ISyndicateRegistry
            .Syndicate({
                syndicateOwner: tokenOwner,
                syndicateContract: tokenContract,
                syndicateDeployer: address(deployerV1),
                syndicateLaunchTime: block.number,
                azimuthPoint: 1
            });

        vm.prank(address(deployerV1));
        vm.expectRevert("Unauthorized: Only active deployers");
        registry.registerSyndicate(syndicate);
    }

    function test_RetrieveOwnerOfFromEcpliticViaRegistryAndAzimuth()
        public
        view
    {
        uint256 samzodPoint = 1024;
        address samzodOwner = registry.ownerOf(samzodPoint);
        console2.log("The input azimuthPoint for samzod is: ", samzodPoint);
        console2.log("~samzod's Owner is: ", samzodOwner);

        uint256 fitdegPoint = 57973;
        address fitdegOwner = registry.ownerOf(fitdegPoint);
        console2.log("The input azimuthPoint for fitdeg is: ", fitdegPoint);
        console2.log("~fitdeg's Owner is: ", fitdegOwner);
    }

    //// Deployer Tests
    function test_DeactivateRegisteredDeployerByOwner() public {
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );
        assertEq(
            dataBeforeDeactivation.isActive,
            registry.isActiveDeployer(address(deployerV1)),
            "Mapping and array values for is active should be the same prior to deactivation"
        );

        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerDeactivated(address(deployerV1), false);

        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        ISyndicateRegistry.SyndicateDeployerData memory currentData = registry
            .getDeployerData(address(deployerV1));

        assertEq(currentData.isActive, false, "Deployer should be deactivated");
        assertEq(
            currentData.isActive,
            registry.isActiveDeployer(address(deployerV1)),
            "Mapping and array values for is active should be the same following deactivation"
        );
    }

    function test_RevertOnDeactivateRegisteredDeployerByNotOwner() public {
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    function test_ReactivateRegisteredDeployerByOwner() public {
        // Register the deployer
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerDeactivated(address(deployerV1), false);

        // Deactivate the deployer
        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        ISyndicateRegistry.SyndicateDeployerData memory currentData = registry
            .getDeployerData(address(deployerV1));

        assertEq(
            currentData.isActive,
            false,
            "Deployer should be deactivated at this stage"
        );

        // Reactivate the Deployer
        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerReactivated(address(deployerV1), true);

        vm.prank(owner);
        registry.reactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData memory newData = registry
            .getDeployerData(address(deployerV1));

        assertEq(
            newData.isActive,
            true,
            "Deployer should be reactivated at this stage"
        );
        assertEq(
            newData.isActive,
            registry.isActiveDeployer(address(deployerV1)),
            "Deployer array and mapping data should both be active at this stage"
        );
    }

    function test_RevertOnReactivateRegisteredDeployerByNotOwner() public {
        // Register the deployer
        vm.prank(owner);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );

        ISyndicateRegistry.SyndicateDeployerData
            memory dataBeforeDeactivation = registry.getDeployerData(
                address(deployerV1)
            );
        assertEq(
            dataBeforeDeactivation.isActive,
            true,
            "Deployer should be active at this stage"
        );

        vm.expectEmit(true, false, false, true); // index 1 has value, 2 and 3 no value, 4 has data for non-indexed values
        emit ISyndicateRegistry.DeployerDeactivated(address(deployerV1), false);

        // Deactivate the deployer
        vm.prank(owner);
        registry.deactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
        ISyndicateRegistry.SyndicateDeployerData memory currentData = registry
            .getDeployerData(address(deployerV1));

        assertEq(
            currentData.isActive,
            false,
            "Deployer should be deactivated at this stage"
        );

        // Attempt to reactivate the Deployer as non-owner
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        registry.reactivateDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    function test_LaunchAndRegisterNewSyndicate() public {
        _registerDeployer();
        _launchSyndicateToken();
        address launchedTokenOwner = _getTbaAddress(
            address(tbaImplementation),
            1024
        );
        assertEq(
            launchedSyndicate.getOwner(),
            launchedTokenOwner,
            "Syndicate owner mismatch"
        );
    }

    function test_ChangeSyndicateDeployerFeeRecipientByRegistryOwner() public {
        _registerDeployer();
        address feeRecipient = deployerV1.getFeeRecipient();
        console2.log("Fee recipient upon deployment is: ", feeRecipient);
        console2.log("Registry owner is: ", registry.getOwner());
        address newRecipient = makeAddr("newRecipient");
        vm.prank(owner);
        deployerV1.changeFeeRecipient(newRecipient);
        console2.log("New recipient is: ", deployerV1.getFeeRecipient());
        assertEq(
            newRecipient,
            deployerV1.getFeeRecipient(),
            "New recipient should be updated in the deployerV1 contract state"
        );
    }

    function test_RevertOnChangeSyndicateDeployerFeeRecipientByRegistryNotOwner()
        public
    {
        _registerDeployer();
        address feeRecipient = deployerV1.getFeeRecipient();
        console2.log("Fee recipient upon deployment is: ", feeRecipient);
        console2.log("Registry owner is: ", registry.getOwner());
        address newRecipient = makeAddr("newRecipient");
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        deployerV1.changeFeeRecipient(newRecipient);
        console2.log("Fee recipient remains: ", deployerV1.getFeeRecipient());
        assertEq(
            owner,
            deployerV1.getFeeRecipient(),
            "Recipient should remain the original owner in the deployerV1 contract state"
        );
    }

    function test_ChangeFeeAmountAndRecieveExpectedAmountFromNewMint() public {
        _registerDeployer();
        vm.startPrank(owner);
        deployerV1.proposeFeeChange(300, 6600);
        uint256 thisBlock = block.number;
        vm.roll(thisBlock + 6600);
        assertEq(block.number, thisBlock + 6600, "Block jump failed");
        deployerV1.changeFee();
        vm.stopPrank();
        uint256 newFee = deployerV1.getFee();
        console2.log("The current fee in basis points is: ", newFee);

        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        uint256 samzodBalance = launchedSyndicate.balanceOf(
            tbaAddressForSamzod
        );
        console2.log("Samzod's initial balance is: ", samzodBalance);

        uint256 feeRecipientBalance = launchedSyndicate.balanceOf(owner);
        console2.log(
            "Owner / initial fee recipient balance is: ",
            feeRecipientBalance
        );
        assertEq(
            feeRecipientBalance,
            (DEFAULT_MINT * newFee) / 10000,
            "Expected fee mismatch"
        );
        assertEq(
            samzodBalance,
            DEFAULT_MINT - ((DEFAULT_MINT * newFee) / 10000),
            "Expected initial owner balance mismatch"
        );
    }

    function test_RevertOnProposeNewFeeAndAttemptFeeChangeImmediately() public {
        _registerDeployer();
        vm.startPrank(owner);
        deployerV1.proposeFeeChange(300, 6600);
        uint256 thisBlock = block.number;
        console2.log("Blockheight is: ", thisBlock);
        vm.expectRevert("Unauthorized: Rate change still timelocked");
        deployerV1.changeFee();
    }

    function test_RevertOnAttemptFeeChangeImmediatelyWithoutProposal() public {
        _registerDeployer();
        vm.startPrank(owner);
        vm.expectRevert("Unauthorized: Fee must be proposed first");
        deployerV1.changeFee();
    }

    function test_RevertOnProposeNewFeeWithTooShortADelay() public {
        _registerDeployer();
        vm.startPrank(owner);
        vm.expectRevert(
            "Unauthorized: Proposed delay must be at least 6600 blocks"
        );
        deployerV1.proposeFeeChange(300, 600);
    }

    function test_ProposeNewFeeAndThenReproposeFeeBeforeChanging() public {
        _registerDeployer();
        vm.startPrank(owner);

        deployerV1.proposeFeeChange(300, 66000);
        uint256 initialRateChangeBlockheight = deployerV1
            .getRateChangeBlockheight();
        console2.log(
            "Initial rate change blockheight: ",
            initialRateChangeBlockheight
        );

        vm.roll(block.number + 1);
        deployerV1.proposeFeeChange(300, 6600);

        uint256 rateChangeBlockheight = deployerV1.getRateChangeBlockheight();
        console2.log("Actual rate change blockheight: ", rateChangeBlockheight);

        vm.roll(block.number + 6600);
        deployerV1.changeFee();
    }

    function test_ChangeFeeRecipientAndRecieveExpectedAmountFromNewMint()
        public
    {
        _registerDeployer();
        vm.prank(owner);
        deployerV1.changeFeeRecipient(bob);
        uint256 protocolFee = deployerV1.getFee();
        console2.log("The current fee in basis points is: ", protocolFee);

        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        uint256 samzodBalance = launchedSyndicate.balanceOf(
            tbaAddressForSamzod
        );
        console2.log("Samzod's initial balance is: ", samzodBalance);

        uint256 feeRecipientBalance = launchedSyndicate.balanceOf(bob);

        console2.log("Updated fee recipient balance is: ", feeRecipientBalance);

        uint256 oldOwnerBalance = launchedSyndicate.balanceOf(owner);
        console2.log(
            "Registry owner / old fee recipient balance is: ",
            oldOwnerBalance
        );

        assertEq(
            FEE,
            protocolFee,
            "Protocol fee should be unchanged from initialization value"
        );
        assertEq(
            feeRecipientBalance,
            (DEFAULT_MINT * protocolFee) / 10000,
            "Expected fee mismatch"
        );
        assertEq(
            samzodBalance,
            DEFAULT_MINT - ((DEFAULT_MINT * protocolFee) / 10000),
            "Expected initial owner balance mismatch"
        );

        vm.prank(tbaAddressForSamzod);
        launchedSyndicate.mint(alice, DEFAULT_MINT);
        uint256 aliceBalance = launchedSyndicate.balanceOf(alice);
        console2.log("Alice has recieved tokens: ", aliceBalance);
        assertEq(
            aliceBalance,
            DEFAULT_MINT - ((DEFAULT_MINT * protocolFee) / 10000),
            "Alice recieved unexpected number of tokens"
        );
        uint256 secondMintFeeRecipientBalance = launchedSyndicate.balanceOf(
            bob
        );
        uint256 currentTotalSupply = launchedSyndicate.totalSupply();
        console2.log("Current total supply is: ", currentTotalSupply);
        assertEq(
            secondMintFeeRecipientBalance,
            currentTotalSupply - (aliceBalance + samzodBalance),
            "Current total supply has a mismatch error"
        );
    }

    function test_AddPermissionedContractMappingToDeployerByRegistryOwner()
        public
    {
        _registerDeployer();
        permissionedContract = makeAddr("permissionedContract");
        vm.prank(owner);
        deployerV1.addPermissionedContract(permissionedContract);
        assertEq(
            deployerV1.isPermissionedContract(permissionedContract),
            true,
            "Contract not successfully added to mapping"
        );
    }

    function test_RevertOnAddPermissionedContractMappingToDeployerByNotRegistryOwner()
        public
    {
        _registerDeployer();
        permissionedContract = makeAddr("permissionedContract");
        vm.prank(bob);
        vm.expectRevert("Unauthorized: Only registry owner");
        deployerV1.addPermissionedContract(permissionedContract);

        assertEq(
            deployerV1.isPermissionedContract(permissionedContract),
            false,
            "Contract mysteriously added to mapping"
        );
    }

    function testFuzz_RevertOnDissolveSyndicateViaDeployerByNotSyndicateTokenContract(
        address[] calldata randomCallers
    ) public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert(
                "Unauthorized: Only syndicates launched from this deployer"
            );
            deployerV1.dissolveSyndicateInRegistry(1024);
        }
    }

    function test_BetaModeWhitelistOnlyAllowsPermissionedAccess() public {
        _registerDeployer();
        vm.startPrank(owner);
        deployerV1.toggleBetaMode(true);
        deployerV1.addWhitelistedPoint(1024);
        vm.stopPrank();
        _launchSyndicateToken();
        bool syndicateExists = registry
            .getSyndicateTokenExistsUsingAzimuthPoint(1024);
        assertEq(syndicateExists, true, "~samzod syndicate not launched");
    }

    function testFail_BetaModeWhitelistBlocksNonPermissionedAccess() public {
        _registerDeployer();
        vm.prank(owner);
        deployerV1.toggleBetaMode(true);
        _launchSyndicateToken();
        bool syndicateExists = registry
            .getSyndicateTokenExistsUsingAzimuthPoint(1024);
        assertEq(
            syndicateExists,
            false,
            "~samzod syndicate circumvented beta whitelist"
        );
    }

    function test_BetaModeWhitelistOffStillAllowsPermissionedAccess() public {
        _registerDeployer();
        vm.startPrank(owner);
        deployerV1.toggleBetaMode(true);
        deployerV1.addWhitelistedPoint(1024);
        deployerV1.toggleBetaMode(false);
        vm.stopPrank();
        _launchSyndicateToken();
        bool syndicateExists = registry
            .getSyndicateTokenExistsUsingAzimuthPoint(1024);
        assertEq(syndicateExists, true, "~samzod syndicate not launched");
    }

    function test_OnlyUnlaunchedSyndicatesCanLaunchASyndicateContract() public {
        _registerDeployer();
        _launchSyndicateToken();

        vm.prank(tbaAddressForSamzod);
        vm.expectRevert("This syndicate already exists");
        address duplicateSyndicateToken = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            DEFAULT_MAXSUPPLY,
            1024,
            "~samzod duplicate syndicate",
            "~SAMDUO"
        );
        console2.log(
            "Duplicate contract launched at: ",
            duplicateSyndicateToken
        );
    }

    //// Syndicate Token Tests

    function test_UpdateSyndicateOwnershipAddressToValidTba() public {
        _registerDeployer();
        _launchSyndicateToken();

        address launchedTokenOwner = _getTbaAddress(
            address(tbaImplementation),
            1024
        );
        address newOwnershipTba = _getTbaAddress(
            address(NULL_IMPLEMENTATION),
            1024
        );

        vm.prank(address(launchedTokenOwner));
        launchedSyndicate.updateOwnershipTba(
            newOwnershipTba,
            address(NULL_IMPLEMENTATION),
            SALT
        );
        console2.log(
            "New Owner of ",
            address(launchedSyndicate),
            "is: ",
            launchedSyndicate.getOwner()
        );
        assertEq(
            newOwnershipTba,
            launchedSyndicate.getOwner(),
            "Syndicate Token Owner failed to update properly"
        );
    }

    function test_WIPDissolveAndRelaunchSyndicate() public {
        _registerDeployer();

        address dissolvableSyndicate;

        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);

        vm.startPrank(tbaAddressForSamzod);
        console2.log(msg.sender);
        dissolvableSyndicate = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            DEFAULT_MAXSUPPLY,
            1024,
            "~samzod dissolvable syndicate",
            "~SAMDIS"
        );

        SyndicateTokenV1(payable(dissolvableSyndicate)).dissolveSyndicate();
        vm.stopPrank();

        bool stillExists = registry.getSyndicateTokenExistsUsingAzimuthPoint(
            1024
        );
        if (stillExists) {
            // Reverts if provided address is not in the mapping
            ISyndicateRegistry.Syndicate
                memory azimuthPointToSyndicateMapping = registry
                    .getSyndicateUsingTokenAddress(dissolvableSyndicate);
            uint256 addressToAzimuthPointMapping = registry
                .getSyndicateAzimuthPointUsingAddress(dissolvableSyndicate);
            console2.log(
                "Dissolved Syndicate owner:",
                azimuthPointToSyndicateMapping.syndicateOwner
            );
            console2.log(
                "Dissolved Syndicate contract:",
                azimuthPointToSyndicateMapping.syndicateContract
            );
            console2.log(
                "Dissolved Syndicate deployer:",
                azimuthPointToSyndicateMapping.syndicateDeployer
            );
            console2.log(
                "Dissolved Syndicate launch time:",
                azimuthPointToSyndicateMapping.syndicateLaunchTime
            );
            console2.log(
                "Dissolved Syndicate azimuth point:",
                azimuthPointToSyndicateMapping.azimuthPoint
            );
            console2.log(
                "Dissolved Syndicate address points to Azimuth Point: ",
                addressToAzimuthPointMapping
            );

            assertEq(address(0), azimuthPointToSyndicateMapping.syndicateOwner);
            assertEq(
                address(0),
                azimuthPointToSyndicateMapping.syndicateContract
            );
            assertEq(
                address(0),
                azimuthPointToSyndicateMapping.syndicateDeployer
            );
            assertEq(
                uint256(0),
                azimuthPointToSyndicateMapping.syndicateLaunchTime
            );
            assertEq(uint256(0), azimuthPointToSyndicateMapping.azimuthPoint);
            assertEq(
                addressToAzimuthPointMapping,
                0,
                "Syndicate Token address should return default value of 0 from _addressToAzimuthPoint mapping"
            );
        }

        assertEq(stillExists, false, "Syndicate should no longer exist");

        _launchSyndicateToken();

        bool relaunchedExists = registry
            .getSyndicateTokenExistsUsingAzimuthPoint(1024);

        ISyndicateRegistry.Syndicate
            memory relaunchedAzimuthPointToSyndicateMapping = registry
                .getSyndicateUsingTokenAddress(address(launchedSyndicate));
        uint256 relaunchedAddressToAzimuthPointMapping = registry
            .getSyndicateAzimuthPointUsingAddress(address(launchedSyndicate));
        console2.log(
            "Relaunched Syndicate owner:",
            relaunchedAzimuthPointToSyndicateMapping.syndicateOwner
        );
        console2.log(
            "Relaunched Syndicate contract:",
            relaunchedAzimuthPointToSyndicateMapping.syndicateContract
        );
        console2.log(
            "Relaunched Syndicate deployer:",
            relaunchedAzimuthPointToSyndicateMapping.syndicateDeployer
        );
        console2.log(
            "Relaunched Syndicate launch time:",
            relaunchedAzimuthPointToSyndicateMapping.syndicateLaunchTime
        );
        console2.log(
            "Relaunched Syndicate azimuth point:",
            relaunchedAzimuthPointToSyndicateMapping.azimuthPoint
        );
        console2.log(
            "Relaunched Syndicate address points to Azimuth Point: ",
            relaunchedAddressToAzimuthPointMapping
        );
        assertEq(relaunchedExists, true, "Relaunched syndicate should exist");
    }

    function test_RevertOnUpdateSyndicateOwnerAddressToInvalidAddress() public {
        address randomNonTba = makeAddr("randomNonTba");
        _registerDeployer();
        _launchSyndicateToken();

        vm.startPrank(tbaAddressForSamzod);
        vm.expectRevert();
        SyndicateTokenV1(payable(launchedSyndicate)).updateOwnershipTba(
            randomNonTba,
            address(tbaImplementation),
            SALT
        );
    }

    function testFuzz_RevertOnUpdateSyndicateOwnerAddressAsNonOwner(
        address[] calldata randomCallers
    ) public {
        _registerDeployer();
        _launchSyndicateToken();

        address secondTbaAddressForSamzod = _getTbaAddress(
            address(NULL_IMPLEMENTATION),
            1024
        );

        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (
                randomCallers[i] == address(0) ||
                randomCallers[i] == tbaAddressForSamzod
            ) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert("Unauthorized: Only syndicate owner");
            SyndicateTokenV1(payable(launchedSyndicate)).updateOwnershipTba(
                secondTbaAddressForSamzod,
                address(NULL_IMPLEMENTATION),
                SALT
            );
        }
        assertEq(
            tbaAddressForSamzod,
            registry.getSyndicateTokenOwnerAddressUsingAddress(
                address(launchedSyndicate)
            ),
            "Syndicate token owner should be the original TBA for ~samzod"
        );
    }

    function test_MintToAddressByOwnerAndFeePaidToFeeRecipient() public {
        _registerDeployer();
        _launchSyndicateToken();
        vm.prank(tbaAddressForSamzod);
        SyndicateTokenV1 samzodSyndicate = SyndicateTokenV1(
            payable(launchedSyndicate)
        );
        samzodSyndicate.mint(bob, 10000 * 1e18);

        uint256 bobsBalance = samzodSyndicate.balanceOf(bob);
        uint256 ecosystemOwnersBalance = samzodSyndicate.balanceOf(owner);
        uint256 samzodsBalance = samzodSyndicate.balanceOf(tbaAddressForSamzod);
        uint256 totalSamzodSupply = samzodSyndicate.totalSupply();

        console2.log("Bob's address is: ", address(bob));
        console2.log("Bob's Balance is: ", bobsBalance);
        console2.log("the Ecosystem Owner's address is: ", address(owner));
        console2.log("Ecosystem Owners's Balance is: ", ecosystemOwnersBalance);

        assertEq(
            bobsBalance + ecosystemOwnersBalance + samzodsBalance,
            totalSamzodSupply,
            "Expected balances mismatch with total supply"
        );
    }

    function testFuzz_RevertOnMintToAddressByNonOwner(
        address[] calldata randomCallers
    ) public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (
                randomCallers[i] == address(0) ||
                randomCallers[i] == tbaAddressForSamzod
            ) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert("Unauthorized: Only syndicate owner");
            launchedSyndicate.mint(bob, 10000 * 1e18);
        }
    }

    function test_BatchMintToAddressByOwnerAndFeePaidToFeeRecipient() public {
        address recipient1 = makeAddr("recipient1");
        address recipient2 = makeAddr("recipient2");
        address recipient3 = makeAddr("recipient3");
        address recipient4 = makeAddr("recipient4");

        uint256 amount1 = 10000 * 1e18;
        uint256 amount2 = 12000 * 1e18;
        uint256 amount3 = 14000 * 1e18;
        uint256 amount4 = 18000 * 1e18;

        uint256 totalMintAmount = (amount1 + amount2 + amount3 + amount4);
        uint256 expectedMintFees = ((amount1 + amount2 + amount3 + amount4) *
            FEE) / 10000;
        uint256 netMintAmount = (totalMintAmount - expectedMintFees);

        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        uint256 preMintSupply = launchedSyndicate.totalSupply();
        uint256 preBatchFees = launchedSyndicate.balanceOf(owner);
        console2.log("Pre-Batch fees to ecosystem owner are: ", preBatchFees);

        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = amount1;
        amounts[1] = amount2;
        amounts[2] = amount3;
        amounts[3] = amount4;

        vm.prank(tbaAddressForSamzod);

        launchedSyndicate.batchMint(recipients, amounts);
        uint256 balance1 = launchedSyndicate.balanceOf(recipient1);
        uint256 balance2 = launchedSyndicate.balanceOf(recipient2);
        uint256 balance3 = launchedSyndicate.balanceOf(recipient3);
        uint256 balance4 = launchedSyndicate.balanceOf(recipient4);
        uint256 balanceFees = launchedSyndicate.balanceOf(owner);
        uint256 balanceSamzod = launchedSyndicate.balanceOf(
            tbaAddressForSamzod
        );
        uint256 totalSamzodSupply = launchedSyndicate.totalSupply();

        console2.log("Recipient 1 balance is: ", balance1);
        console2.log("Recipient 2 balance is: ", balance2);
        console2.log("Recipient 3 balance is: ", balance3);
        console2.log("Recipient 4 balance is: ", balance4);
        console2.log("Expected batch mint fees are: ", expectedMintFees);
        console2.log("Fee Recipient Balance is: ", balanceFees);

        assertEq(
            totalSamzodSupply,
            (balance1 +
                balance2 +
                balance3 +
                balance4 +
                balanceFees +
                balanceSamzod),
            "Total Supply not matching expected supply based on balances"
        );
        assertEq(
            totalSamzodSupply,
            (netMintAmount + expectedMintFees + preMintSupply),
            "Total supply not matching expected supply based on mint broken down on fees, plus pre-mint supply"
        );
    }

    function test_TurnOnCustomWhitelistByOwner() public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.toggleDefaultWhitelist(true);
        assertEq(
            launchedSyndicate.usesDefaultWhitelist(),
            true,
            "Mismatch on Whitelist toggle to true"
        );
    }

    function testFuzz_RevertOnTurnOnCustomWhitelistByNonOwner(
        address[] calldata randomCallers
    ) public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);

        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.startPrank(randomCallers[i]);
            vm.expectRevert();
            launchedSyndicate.toggleDefaultWhitelist(true);
            assertEq(
                launchedSyndicate.usesDefaultWhitelist(),
                false,
                "Non-owner managed to change default whitelist flag"
            );
        }
    }

    function test_TurnOffCustomWhitelistByOwner() public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.toggleDefaultWhitelist(true);
        assertEq(
            launchedSyndicate.usesDefaultWhitelist(),
            true,
            "Mismatch on Whitelist toggle to true"
        );
        launchedSyndicate.toggleDefaultWhitelist(false);
        assertEq(
            launchedSyndicate.usesDefaultWhitelist(),
            false,
            "Owner failed to toggle default whitelist"
        );
    }

    function testFuzz_RevertOnTurnOffCustomWhitelistByNonOwner(
        address[] calldata randomCallers
    ) public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.toggleDefaultWhitelist(true);
        assertEq(
            launchedSyndicate.usesDefaultWhitelist(),
            true,
            "Mismatch on Whitelist toggle to true"
        );
        vm.stopPrank();

        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.startPrank(randomCallers[i]);
            vm.expectRevert();
            launchedSyndicate.toggleDefaultWhitelist(false);
            assertEq(
                launchedSyndicate.usesDefaultWhitelist(),
                true,
                "Non-owner managed to change default whitelist flag"
            );
        }
    }

    function test_FreeMintViaCustomWhitelistByPermissionedAddress() public {
        _registerDeployer();
        permissionedContract = makeAddr("permissionedContract");
        vm.prank(owner);
        deployerV1.addPermissionedContract(permissionedContract);
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.prank(tbaAddressForSamzod);
        launchedSyndicate.toggleDefaultWhitelist(true);
        assertEq(
            launchedSyndicate.usesDefaultWhitelist(),
            true,
            "Mismatch on Whitelist toggle to true"
        );

        uint256 mintAmount = 2700 * 1e18;
        vm.prank(permissionedContract);
        launchedSyndicate.permissionedMint(bob, mintAmount);
        uint256 bobsBalance = launchedSyndicate.balanceOf(bob);
        assertEq(
            mintAmount,
            bobsBalance,
            "Expected Balance does not match mint amount"
        );
    }

    function test_FreeBatchMintToAddressByPermissionedAddress() public {
        // Create mint targets, amounts, and associated arrays
        address recipient1 = makeAddr("recipient1");
        address recipient2 = makeAddr("recipient2");
        address recipient3 = makeAddr("recipient3");
        address recipient4 = makeAddr("recipient4");

        uint256 amount1 = 10000 * 1e18;
        uint256 amount2 = 12000 * 1e18;
        uint256 amount3 = 14000 * 1e18;
        uint256 amount4 = 18000 * 1e18;

        uint256 freeMintAmount = (amount1 + amount2 + amount3 + amount4);

        address[] memory recipients = new address[](4);
        recipients[0] = recipient1;
        recipients[1] = recipient2;
        recipients[2] = recipient3;
        recipients[3] = recipient4;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = amount1;
        amounts[1] = amount2;
        amounts[2] = amount3;
        amounts[3] = amount4;

        // Set up the contract state
        _registerDeployer();
        permissionedContract = makeAddr("permissionedContract");
        vm.prank(owner);
        deployerV1.addPermissionedContract(permissionedContract);
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.prank(tbaAddressForSamzod);
        launchedSyndicate.toggleDefaultWhitelist(true);

        uint256 preMintSupply = launchedSyndicate.totalSupply();
        uint256 preBatchFees = launchedSyndicate.balanceOf(owner);
        console2.log("Pre-Batch fees to ecosystem owner are: ", preBatchFees);

        // Run core functionality
        vm.prank(permissionedContract);
        launchedSyndicate.permissionedBatchMint(recipients, amounts);

        // Get outputs
        uint256 balance1 = launchedSyndicate.balanceOf(recipient1);
        uint256 balance2 = launchedSyndicate.balanceOf(recipient2);
        uint256 balance3 = launchedSyndicate.balanceOf(recipient3);
        uint256 balance4 = launchedSyndicate.balanceOf(recipient4);
        uint256 balanceFees = launchedSyndicate.balanceOf(owner);
        uint256 balanceSamzod = launchedSyndicate.balanceOf(
            tbaAddressForSamzod
        );
        uint256 totalSamzodSupply = launchedSyndicate.totalSupply();

        console2.log("Recipient 1 balance is: ", balance1);
        console2.log("Recipient 2 balance is: ", balance2);
        console2.log("Recipient 3 balance is: ", balance3);
        console2.log("Recipient 4 balance is: ", balance4);
        console2.log("Fee Recipient Balance is: ", balanceFees);

        assertEq(
            totalSamzodSupply,
            (balance1 +
                balance2 +
                balance3 +
                balance4 +
                balanceFees +
                balanceSamzod),
            "Total Supply not matching expected supply based on balances"
        );
        assertEq(
            totalSamzodSupply,
            (balance1 + balance2 + balance3 + balance4 + preMintSupply),
            "Total supply not matching expected supply based on mint broken down on fees, plus pre-mint supply"
        );
        assertEq(
            preBatchFees,
            balanceFees,
            "Pre and post batch fee recipient balance should match"
        );
    }

    function test_MintByPermissionedAddressWhenOwnerMintableIsFalse() public {
        _registerDeployer();
        permissionedContract = makeAddr("permissionedContract");
        vm.prank(owner);
        deployerV1.addPermissionedContract(permissionedContract);
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.toggleDefaultWhitelist(true);
        assertEq(
            launchedSyndicate.usesDefaultWhitelist(),
            true,
            "Mismatch on Whitelist toggle to true"
        );
        launchedSyndicate.renounceMintingRights();
        assertEq(
            launchedSyndicate.isOwnerMintable(),
            false,
            "Remains ownerMintable after attempting to renounce minting rights"
        );
        vm.stopPrank();

        uint256 mintAmount = 2700 * 1e18;
        vm.prank(permissionedContract);
        launchedSyndicate.permissionedMint(bob, mintAmount);
        uint256 bobsBalance = launchedSyndicate.balanceOf(bob);
        console2.log("Bob's account balance is now: ", bobsBalance);
        assertEq(
            mintAmount,
            bobsBalance,
            "Expected Balance does not match mint amount"
        );
    }

    function test_RevertOnMintByOwnerWhenOwnerMintableIsFalse() public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.renounceMintingRights();
        assertEq(
            launchedSyndicate.isOwnerMintable(),
            false,
            "Remains ownerMintable after attempting to renounce minting rights"
        );
        uint256 mintAmount = 2700 * 1e18;
        vm.expectRevert("Unauthorized: Owner does not have minting rights");
        launchedSyndicate.mint(bob, mintAmount);
    }

    function test_DissolveSyndicateViaTokenByOwner() public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.prank(tbaAddressForSamzod);
        launchedSyndicate.dissolveSyndicate();

        // check registry
        assertEq(
            registry.getSyndicateTokenExistsUsingAzimuthPoint(1024),
            false,
            "Registry failed to clear _syndicate mapping"
        );
        assertEq(
            registry.getSyndicateTokenExistsUsingAddress(samzodSyndicate),
            false,
            "Registry failed to clear _addressToAzimuthPoint mapping"
        );
        // mapping by token contract and AZP
        // check deployer by _deployedSyndicates

        assertEq(
            deployerV1.isRelatedSyndicate(samzodSyndicate),
            false,
            "Deployer failed to clear mapping"
        );
    }

    function testFuzz_RevertOnDissolveSyndicateViaTokenByNotSyndicateOwner(
        address[] calldata randomCallers
    ) public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert("Unauthorized: Only syndicate owner");
            launchedSyndicate.dissolveSyndicate();
        }
    }

    function test_MintThenChangeProtocolFeeToZeroThenFreeMintByOwner() public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));

        uint256 mintAmount = 10000 * 1e18;
        uint256 protocolFee = launchedSyndicate.getProtocolFee();
        address feeRecipient = launchedSyndicate.getFeeRecipient();
        uint256 startingFeeBalance = launchedSyndicate.balanceOf(feeRecipient);
        uint256 expectedFees = (mintAmount * protocolFee) / 10000;
        uint256 expectedBobsBalance = mintAmount - expectedFees;

        vm.prank(tbaAddressForSamzod);
        launchedSyndicate.mint(bob, mintAmount);

        uint256 bobsBalance = launchedSyndicate.balanceOf(bob);
        assertEq(expectedBobsBalance, bobsBalance, "Bob's Balance mismatch");
        console2.log("Bobs expected balance: ", expectedBobsBalance);
        console2.log("Bobs actual balance: ", bobsBalance);

        uint256 feeBalance = launchedSyndicate.balanceOf(feeRecipient);
        assertEq(
            feeBalance,
            expectedFees + startingFeeBalance,
            "Fee Recipient's Balance mismatch"
        );
        console2.log(
            "Fee Recipient expected balance: ",
            expectedFees + startingFeeBalance
        );
        console2.log("Fee Recipient actual balance: ", feeBalance);

        vm.prank(owner);
        launchedSyndicate.reduceFee(0);

        uint256 newFeeRate = launchedSyndicate.getProtocolFee();
        console2.log("New fee rate is: ", newFeeRate);

        vm.prank(tbaAddressForSamzod);
        launchedSyndicate.mint(bob, mintAmount);

        uint256 expectedBobsNewBalance = bobsBalance + mintAmount;
        uint256 bobsNewBalance = launchedSyndicate.balanceOf(bob);
        assertEq(
            expectedBobsNewBalance,
            bobsNewBalance,
            "Bob's Balance mismatch"
        );
        console2.log("Bobs expected new balance: ", expectedBobsBalance);
        console2.log("Bobs actual new balance: ", bobsBalance);

        uint256 feeNewBalance = launchedSyndicate.balanceOf(feeRecipient);
        assertEq(
            feeBalance,
            expectedFees + startingFeeBalance,
            "Fee Recipient's Balance unexpectedly changed"
        );
        console2.log(
            "Fee Recipient expected new balance: ",
            expectedFees + startingFeeBalance
        );
        console2.log("Fee Recipient actual new balance: ", feeBalance);
    }

    function testFuzz_RevertOnAttemptToRaiseProtocolFeeByEcosystemOwner(
        uint256[] calldata randomAmount
    ) public {
        _registerDeployer();
        address samzodSyndicate = _launchSyndicateToken();
        launchedSyndicate = SyndicateTokenV1(payable(samzodSyndicate));
        uint256 currentProtocolFee = launchedSyndicate.getProtocolFee();
        console2.log("Current protocol fee is: ", currentProtocolFee);

        vm.assume(randomAmount.length > 0);
        vm.assume(randomAmount.length <= 256);
        for (uint256 i = 0; i < randomAmount.length; i++) {
            if (randomAmount[i] <= currentProtocolFee) {
                continue;
            }
            uint256 attemptedNewFee = randomAmount[i];
            vm.prank(owner);
            vm.expectRevert(
                "Unauthorized: New fee must be lower than max protocol fee"
            );
            launchedSyndicate.reduceFee(attemptedNewFee);
        }
    }

    function test_RevertOnMintByOwnerOverSupplyCap() public {
        _registerDeployer();
        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        vm.prank(tbaAddressForSamzod);
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            type(uint256).max,
            1024,
            "~samzod-samzod Long-name approved Syndicate",
            "~UNCAPPED"
        );
        launchedSyndicate = SyndicateTokenV1(payable(syndicateTokenV1));

        console2.log(
            "Syndicate Contract Launched at: ",
            address(syndicateTokenV1)
        );
        console2.log("syndicateOwner: ", launchedSyndicate.getOwner());
        console2.log("initialSupply: ", launchedSyndicate.totalSupply());
        console2.log("maxSupply: ", launchedSyndicate.getMaxSupply());
        console2.log("azimiuthPoint: ", launchedSyndicate.getAzimuthPoint());
        console2.log("name: ", launchedSyndicate.name());
        console2.log("symbol: ", launchedSyndicate.symbol());
        assertTrue(
            address(syndicateTokenV1).code.length > 0,
            "Syndicate Token not deployed"
        );

        uint256 newSupplyCap = 1000000 * 1e18;
        uint256 failingMintAmount = 10000 * 1e18;

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.setMaxSupply(newSupplyCap);
        bool isCapped = launchedSyndicate.isSupplyCapped();
        uint256 actualSupplyCap = launchedSyndicate.getMaxSupply();
        assertEq(
            actualSupplyCap,
            newSupplyCap,
            "Supply cap not set to provided value"
        );

        console2.log("Supply Cap is", isCapped);
        assertTrue(isCapped, "Supply is not capped");

        vm.expectRevert("ERC20: Mint over maxSupply limit");
        launchedSyndicate.mint(bob, failingMintAmount);
    }

    function test_RevertOnMintByPermissionedContractOverSupplyCap() public {
        _registerDeployer();
        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        vm.prank(tbaAddressForSamzod);
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            type(uint256).max,
            1024,
            "~samzod Uncapped Syndicate",
            "~UNCAPPED"
        );
        launchedSyndicate = SyndicateTokenV1(payable(syndicateTokenV1));

        console2.log(
            "Syndicate Contract Launched at: ",
            address(syndicateTokenV1)
        );
        console2.log("syndicateOwner: ", launchedSyndicate.getOwner());
        console2.log("initialSupply: ", launchedSyndicate.totalSupply());
        console2.log("maxSupply: ", launchedSyndicate.getMaxSupply());
        console2.log("azimiuthPoint: ", launchedSyndicate.getAzimuthPoint());
        console2.log("name: ", launchedSyndicate.name());
        console2.log("symbol: ", launchedSyndicate.symbol());
        assertTrue(
            address(syndicateTokenV1).code.length > 0,
            "Syndicate Token not deployed"
        );

        uint256 newSupplyCap = 1000000 * 1e18;
        uint256 failingMintAmount = 10000 * 1e18;

        vm.startPrank(tbaAddressForSamzod);
        launchedSyndicate.setMaxSupply(newSupplyCap);
        bool isCapped = launchedSyndicate.isSupplyCapped();
        uint256 actualSupplyCap = launchedSyndicate.getMaxSupply();
        assertEq(
            actualSupplyCap,
            newSupplyCap,
            "Supply cap not set to provided value"
        );

        console2.log("Supply Cap is", isCapped);
        assertTrue(isCapped, "Supply is not capped");

        bool defaultsWhitelisted = launchedSyndicate.toggleDefaultWhitelist(
            true
        );
        console2.log(
            "Syndicate contract uses default whitelist: ",
            defaultsWhitelisted
        );
        assertTrue(
            defaultsWhitelisted,
            "Syndicate token not using default whitelist"
        );
        permissionedContract = makeAddr("permissionedContract");
        vm.stopPrank();

        vm.prank(owner);
        deployerV1.addPermissionedContract(permissionedContract);
        assertEq(
            deployerV1.isPermissionedContract(permissionedContract),
            true,
            "Contract not successfully added to mapping"
        );

        vm.prank(permissionedContract);
        vm.expectRevert("ERC20: Mint over maxSupply limit");
        launchedSyndicate.permissionedMint(bob, failingMintAmount);
    }

    function test_RevertOnDeploySyndicateWithExcessivelyLongName() public {
        _registerDeployer();
        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        vm.prank(tbaAddressForSamzod);
        vm.expectRevert("Invalid name: Must be <50 approved characters");
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            type(uint256).max,
            1024,
            "~samzod-samzod Long-name should block Syndicate deployment",
            "~UNCAPPED"
        );
    }

    function test_RevertOnDeploySyndicateWithExcessivelyLongSymbol() public {
        _registerDeployer();
        tbaAddressForSamzod = _getTbaAddress(address(tbaImplementation), 1024);
        vm.prank(tbaAddressForSamzod);
        vm.expectRevert("Invalid symbol: Must be <16 approved characters");
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            DEFAULT_MINT,
            type(uint256).max,
            1024,
            "~samzod Syndicate",
            "~TOO-LONG-A-SYMBOL"
        );
    }

    // Admin checks

    function testContractSizes() public {
        uint256 registrySize;
        uint256 deployerSize;
        uint256 tokenSize;

        _registerDeployer();
        _launchSyndicateToken();

        address registryAddr = address(registry);
        address deployerAddr = address(deployerV1);
        address tokenAddr = address(launchedSyndicate);

        assembly {
            registrySize := extcodesize(registryAddr)
            deployerSize := extcodesize(deployerAddr)
            tokenSize := extcodesize(tokenAddr)
        }

        console2.log("Registry contract size:", registrySize);
        console2.log("Deployer contract size:", deployerSize);
        console2.log("Token contract size:", tokenSize);
    }
}
