// SPDX-License-Identifier: GPLv3

// TODOs
// properly name all tests
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

contract SyndicateEcosystemTest is Test {
    IERC6551Registry public tbaRegistry;
    IERC721 public azimuthContract;
    IERC6551Account public tbaImplementation;

    SyndicateRegistry public registry;
    SyndicateDeployerV1 public deployerV1;
    SyndicateTokenV1 public launchedSyndicate;

    address public registryAddress;
    address public deployerAddress;

    address public owner;
    address public alice;
    address public bob;
    address public syndicateOwner;

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

        tbaRegistry = IERC6551Registry(vm.envAddress("SEPOLIA_TBA_REGISTRY"));
        azimuthContract = IERC721(vm.envAddress("SEPOLIA_AZIMUTH_CONTRACT"));
        tbaImplementation = IERC6551Account(
            payable(vm.envAddress("SEPOLIA_TBA_IMPLEMENTATION"))
        );

        syndicateOwner = vm.envAddress("SEPOLIA_PUBLIC_KEY_0");

        vm.startPrank(owner);
        registry = new SyndicateRegistry();
        registryAddress = address(registry);

        deployerV1 = new SyndicateDeployerV1(
            address(registry),
            address(azimuthContract),
            FEE
        );
        deployerAddress = address(deployerV1);

        vm.stopPrank();

        // verify fork is working
        assertTrue(
            address(tbaRegistry).code.length > 0,
            "TBA Registry not deployed"
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
        vm.stopPrank();
    }

    //// launch a syndicate token
    function _launchSyndicateToken() public {
        // vm.prank(syndicateOwner);
        address tbaAddressForSamzod = _getTbaAddress(
            address(tbaImplementation),
            1024
        );
        vm.prank(tbaAddressForSamzod);
        address syndicateTokenV1 = deployerV1.deploySyndicate(
            address(tbaImplementation),
            SALT,
            1000000000000000000000000,
            21000000000000000000000000,
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
                address(azimuthContract),
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

    function test_rejectRegistryOwnershipByPendingOwner() public {
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

    //// TODO test_nullifyRegistryOwnershipProposalByOwner
    //// TODO testFail_nullifyRegistryOwnershipProposalByNotOwner
    //// TODO test_renounceRegistryOwnershipByOwner
    //// TODO testFail_renounceRegistryOwnershipByNotOwner

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
        // TODO add more complex version numbering or logic checks?
        // TODO I think this should actually fail due to the registry version already existing?
        assertEq(
            true,
            registry.isRegisteredDeployer(address(deployerV1)),
            "Is not registered deployment"
        );
        // TODO add expect Emit
    }

    function testFail_RegisterNewDeployerByNotOwner() public {
        vm.prank(bob);
        registry.registerDeployer(
            ISyndicateRegistry.SyndicateDeployerData({
                deployerAddress: address(deployerV1),
                deployerVersion: 1,
                isActive: true
            })
        );
    }

    // TODO test_RegisterSecondDeployerByOwner
    // TODO testFail_RegisterSecondDeployerByNotOwner
    // TODO testFail_RegisterDeployerWithExistingVersionNumber

    function testFuzz_RegisterNewDeployerByNotOwner(
        address[] calldata randomCallers
    ) public {
        vm.assume(randomCallers.length > 0);
        vm.assume(randomCallers.length <= 256);
        for (uint256 i = 0; i < randomCallers.length; i++) {
            if (randomCallers[i] == address(0) || randomCallers[i] == owner) {
                continue;
            }
            vm.prank(randomCallers[i]);
            vm.expectRevert();
            registry.registerDeployer(
                ISyndicateRegistry.SyndicateDeployerData({
                    deployerAddress: address(deployerV1),
                    deployerVersion: 1,
                    isActive: true
                })
            );
        }
    }

    // TODO testFuzz_RegisterSyndicateTokenInRegistryByNonDeployer
    // TODO testFuzz_UpdateSyndicateTokenOwnerRegistryByNonDeployer
    // TODO testFail_UpdateSyndicateTokenOwnerRegistryByInactiveDeployer
    // TK Should Token Ownership be updatable by an inactive deployer? Methinks yes.

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
    }

    function testFail_DeactivateRegisteredDeployerByNotOwner() public {
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
    }

    function testFail_ReactivateRegisteredDeployerByNotOwner() public {
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

    // TODO test_ChangeSyndicateDeployerFeeRecipientByRegistryOwner
    // TODO testFail_ChangeSyndicateDeployerFeeRecipientByNotOwner
    // TODO test_ChangeFeeAmountAndRecieveExpectedAmountFromNewMint
    // TODO test_ChangeRecipientAndConfirmAllProtocolFeesGoToNewRecipient
    // TODO test_AddPermissionedContractMappingByOwner
    // TODO testFail_AddPermissionedContractMappingByNotOwner
    // TODO testFuzz_DissolveSyndicateViaDeployerByNotSyndicateTokenContract
    // TODO testFuzz_RegisterSyndicateViaDeployerByNotSyndicateTokenContract

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

    // TODO testFail_UpdateSyndicateOwnershipAddressToInvalidTba
    // TODO testFail_UpdateSyndicateOwnershipAddressAsNotOwner
    // TODO test_MintToAddressByOwnerAndFeePaidToFeeRecipient
    // TODO testFail_MintToAddressByNonOwner
    // TODO test_BatchMintToAddressByOwnerAndFeePaidToFeeRecipient
    // TODO testFail_BatchMintToAddressByNonOwner
    // TODO test_TurnOnCustomWhitelistByOwner
    // TODO testFail_TurnOnCustomWhitelistByNotOwner
    // TODO test_TurnOffCustomWhitelistByOwner
    // TODO test_TurnOffCustomWhitelistByNotOwner
    // TODO test_FreeMintByWhitelistedAddress
    // TODO test_FreeBatchMintByWhitelistedAddress
    // TODO testFail_MintOverMaxSupplyByOwner
    // TODO test_DissolveSyndicateByOwner
    // TODO testFail_DissolveSyndicateByNotOwner
    // TODO test_NewSyndicateAfterDissolutionByUrbitTba
    // TODO testFail_NewSyndicateAfterDissolutionByNotUrbitTBA

    // TODO test_FeeCalculationForBatchMintByOwner
    // TODO test_FeeCalculationForMintByOwner

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

    // Getter function tests
    //// TODO add tests for getter functions if necessary
}
