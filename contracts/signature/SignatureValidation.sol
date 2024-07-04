// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AuthorizationGuardAccess} from "../management/roles/AuthorizationGuardAccess.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TokenOpTypes} from "lib/agau-types/TokenOpTypes.sol";

/**
 * @title MultiSigValidation
 * @dev MultiSigValidation is a contract for managing multi-signature validation,
 * signers, and roles for different operation types.
 * Inherits from AuthorizationGuardAccess to leverage role-based access control.
 */
contract MultiSigValidation is AuthorizationGuardAccess {
    using ECDSA for bytes32;

    struct Role {
        string name;
        address signerAddress;
    }

    struct SignerEntity {
        address signerAddress;
        string roleName;
        TokenOpTypes.OpType operationType;
    }

    struct UpdateSignerEntity {
        address currentSigner;
        address newSigner;
        TokenOpTypes.OpType operationType;
    }

    mapping(TokenOpTypes.OpType => mapping(address => string)) public roles;
    mapping(TokenOpTypes.OpType => mapping(uint256 => address)) public unsortedSignersRegistry;
    mapping(TokenOpTypes.OpType => uint256) public requiredSignatures;

    mapping(TokenOpTypes.OpType => mapping(bytes32 => mapping(address => bool))) public signatures;
    mapping(bytes32 => uint256) public signatureCount;
    mapping(bytes32 => bool) public usedHashes;

    event SignatureValidated(
        address operator,
        TokenOpTypes.OpType operationType,
        bytes32 operationMessageHash,
        bytes[] signatures
    );
    event SignatureReceived(address signer, bytes32 hash, string roleName);
    event SignerAdded(string roleName, address signerAddress, TokenOpTypes.OpType operationType);
    event SignerRemoved(string roleName, address signerAddress, TokenOpTypes.OpType operationType);
    event SignerUpdated(
        string roleName,
        address newSigner,
        address previousSigner,
        TokenOpTypes.OpType operationType
    );

    /**
     * @dev Initializes the contract by setting the authorization guard address and adding initial signers.
     * @param _authorizationGuardAddress Address of the authorization guard.
     * @param _mintSigners Array of initial mint signers.
     * @param _releaseSigners Array of initial release signers.
     */
    constructor(
        address _authorizationGuardAddress,
        SignerEntity[] memory _mintSigners,
        SignerEntity[] memory _releaseSigners
    ) {
        __AuthorizationGuardAccess_init(_authorizationGuardAddress);
        require(_mintSigners.length > 0, "No mint signers specified");
        require(_releaseSigners.length > 0, "No release signers specified");

        addSigners(_mintSigners);
        addSigners(_releaseSigners);
    }

    /**
     * @dev Generates a hash of the common operation message.
     * @param functionName Name of the function to be included in the hash.
     * @param message Struct containing common token operation signature data.
     * @return Hash of the common operation message.
     */
    function getMessageHashCommon(
        string memory functionName,
        TokenOpTypes.CommonTokenOpSignatureData memory message
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    functionName,
                    message.account,
                    message.weight,
                    message.metalId,
                    message.documentHash
                )
            );
    }

    /**
     * @dev Verifies the signatures for a common operation.
     * @param functionName Name of the function for which the signature is being verified.
     * @param operationType Type of the operation.
     * @param instruction Struct containing common token operation signature data.
     * @return True if the signatures are valid, false otherwise.
     */
    function verifyCommonOpSignature(
        string memory functionName,
        TokenOpTypes.OpType operationType,
        TokenOpTypes.CommonTokenOpWithSignature memory instruction
    ) external onlyTrustedContracts returns (bool) {
        bytes32 _hash = getMessageHashCommon(
            functionName,
            TokenOpTypes.CommonTokenOpSignatureData({
                account: instruction.account,
                weight: instruction.weight,
                metalId: instruction.metalId,
                documentHash: instruction.documentHash
            })
        );
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        require(prefixedHash == instruction.signatureHash, "Invalid hash");

        bool isValid = validateSignatures(prefixedHash, instruction.signatures, operationType);

        // Ensure that the validation was successful
        require(isValid, "Invalid signatures");

        return true;
    }

    /**
     * @dev Validates the signatures for a given hash and operation type.
     * @param _hash Hash of the operation message.
     * @param signaturesArray Array of signatures to be validated.
     * @param operationType Type of the operation.
     * @return True if the signatures are valid, false otherwise.
     */
    function validateSignatures(
        bytes32 _hash,
        bytes[] memory signaturesArray,
        TokenOpTypes.OpType operationType
    ) internal returns (bool) {
        require(
            signaturesArray.length == requiredSignatures[operationType],
            "Invalid number of signatures"
        );

        require(!usedHashes[_hash], "Hash has already been used for minting");

        for (uint256 i = 0; i < signaturesArray.length; i++) {
            address signer = recoverSigner(_hash, signaturesArray[i]);
            require(isSigner(signer, operationType), "Invalid signer for role");
            require(!signatures[operationType][_hash][signer], "Signature for role already used");

            signatures[operationType][_hash][signer] = true;
            signatureCount[_hash]++;

            emit SignatureReceived(signer, _hash, getRole(operationType, signer));
        }

        require(
            signatureCount[_hash] >= requiredSignatures[operationType],
            "Not enough valid signatures"
        );

        // Mark the hash as used
        usedHashes[_hash] = true;

        emit SignatureValidated(msg.sender, operationType, _hash, signaturesArray);
        return true;
    }

    /**
     * @dev Returns the list of signers for a given operation type
     * @param operationType The type of operation to sign by signers group (0 for mint, 1 for release)
     */
    function getSignerRegistry(
        TokenOpTypes.OpType operationType
    ) public view returns (address[] memory) {
        address[] memory signersGroup = new address[](requiredSignatures[operationType]);
        for (uint256 i = 0; i < requiredSignatures[operationType]; i++) {
            signersGroup[i] = unsortedSignersRegistry[operationType][i];
        }
        return signersGroup;
    }

    /**
     * @dev Checks if an address is a signer for a specific operation type.
     * @param _address Address to be checked.
     * @param operationType Type of the operation.
     * @return True if the address is a signer, false otherwise.
     */
    function isSigner(
        address _address,
        TokenOpTypes.OpType operationType
    ) public view returns (bool) {
        string memory roleName = roles[operationType][_address];

        return keccak256(abi.encodePacked(roleName)) != keccak256(abi.encodePacked(""));
    }

    /**
     * @dev Recovers the signer's address from the hash and signature.
     * @param _hash Hash of the signed message.
     * @param signature Signature to be recovered.
     * @return Address of the signer.
     */
    function recoverSigner(bytes32 _hash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        return messageDigest.recover(signature);
    }

    /**
     * @dev Adds new signers to the roles mapping and adds it to the signers registry.
     * @param signers Array of signers to be added.
     */
    function addSigners(SignerEntity[] memory signers) public onlyAdminAccess {
        for (uint32 i = 0; i < signers.length; i++) {
            require(signers[i].signerAddress != address(0), "Invalid address");
            if (!isSigner(signers[i].signerAddress, signers[i].operationType)) {
                // Add signer address to registry list
                bool isRegistered = registerSigner(
                    signers[i].signerAddress,
                    signers[i].roleName,
                    signers[i].operationType
                );
                require(isRegistered, "Failed to register signer");

                emit SignerAdded(
                    signers[i].roleName,
                    signers[i].signerAddress,
                    signers[i].operationType
                );
            }
        }
    }

    /**
     * @dev Removes signers from the roles mapping and deregisters it from the signers registry.
     * @param signers Array of signers to be removed.
     */
    function removeSigners(SignerEntity[] memory signers) public onlyAdminAccess {
        for (uint32 i = 0; i < signers.length; i++) {
            if (isSigner(signers[i].signerAddress, signers[i].operationType)) {
                bool isDeregistered = deregisterSigner(
                    signers[i].signerAddress,
                    signers[i].operationType
                );

                require(isDeregistered, "Failed to deregister signer");

                emit SignerRemoved(
                    signers[i].roleName,
                    signers[i].signerAddress,
                    signers[i].operationType
                );
            }
        }
    }

    /**
     * @dev Add role for signers and add signer to the specified group (registry)
     * @param newSigner The address of the new signer
     * @param roleName The name of the role held by the new signer
     * @param operationType The type of operation to sign by signers group (0 for mint, 1 for release)
     * @return bool Returns registration result as a boolean
     */
    function registerSigner(
        address newSigner,
        string memory roleName,
        TokenOpTypes.OpType operationType
    ) internal returns (bool) {
        unsortedSignersRegistry[operationType][requiredSignatures[operationType]] = newSigner;
        requiredSignatures[operationType] += 1;

        roles[operationType][newSigner] = roleName;

        return true;
    }

    /**
     * @dev Remove role for signers and remove signer from the specified group (registry)
     * @param targetSigner The current signer address to deregister
     * @param operationType The type of operation to sign by signers group (0 for mint, 1 for release)
     * @return bool Returns deregistration result as a boolean
     */
    function deregisterSigner(
        address targetSigner,
        TokenOpTypes.OpType operationType
    ) internal returns (bool) {
        require(requiredSignatures[operationType] > 0, "No signers for this operation");

        uint256 signersLength = requiredSignatures[operationType];
        for (uint256 i = 0; i < signersLength; i++) {
            address existingSigner = unsortedSignersRegistry[operationType][i];

            if (existingSigner == targetSigner) {
                // Check if match is at the end of the hypothetical list
                if (i == signersLength - 1) {
                    // Delete the last address in the list
                    unsortedSignersRegistry[operationType][i] = address(0);
                } else {
                    // Match is somewhere not at the end
                    // Copy the address to delete to the end of the list
                    unsortedSignersRegistry[operationType][i] = unsortedSignersRegistry[
                        operationType
                    ][signersLength - 1];
                }

                // Update required signers count for the operation
                requiredSignatures[operationType] -= 1;

                // Clear role for wallet address
                roles[operationType][targetSigner] = "";

                return true;
            }
        }
        return false;
    }

    /**
     * @dev Updates signers in the roles mapping.
     * @param updateInstructions Array of instructions to update signers.
     */
    function updateSigner(UpdateSignerEntity[] memory updateInstructions) public onlyAdminAccess {
        for (uint32 i = 0; i < updateInstructions.length; i++) {
            require(
                isSigner(updateInstructions[i].currentSigner, updateInstructions[i].operationType),
                "Address for current signer is not a signer"
            );
            require(
                !isSigner(updateInstructions[i].newSigner, updateInstructions[i].operationType),
                "New signer is already a signer"
            );

            string memory roleName = roles[updateInstructions[i].operationType][
                updateInstructions[i].currentSigner
            ];

            bool isDeregistered = deregisterSigner(
                updateInstructions[i].currentSigner,
                updateInstructions[i].operationType
            );

            require(isDeregistered, "Failed to deregister current signer");

            bool isRegistered = registerSigner(
                updateInstructions[i].newSigner,
                roleName,
                updateInstructions[i].operationType
            );
            require(isRegistered, "Failed to register new signer");

            // roles[updateInstructions[i].operationType][updateInstructions[i].newSigner] = roles[
            //     updateInstructions[i].operationType
            // ][updateInstructions[i].currentSigner];

            // roles[updateInstructions[i].operationType][updateInstructions[i].currentSigner] = "";

            emit SignerUpdated(
                roles[updateInstructions[i].operationType][updateInstructions[i].newSigner],
                updateInstructions[i].newSigner,
                updateInstructions[i].currentSigner,
                updateInstructions[i].operationType
            );
        }
    }

    /**
     * @dev Retrieves the role of a signer for a specific operation type.
     * @param operationType Type of the operation.
     * @param signer Address of the signer.
     * @return Role of the signer.
     */
    function getRole(
        TokenOpTypes.OpType operationType,
        address signer
    ) public view returns (string memory) {
        return roles[operationType][signer];
    }
}
