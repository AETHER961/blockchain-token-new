// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AuthorizationGuardAccess} from "../management/roles/AuthorizationGuardAccess.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {TokenOpTypes} from "lib/agau-types/TokenOpTypes.sol";

/*
    * Pass to the constructor the number of required signatures and the authorization guard address.

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
    }

    mapping(TokenOpTypes.OpType => Role[]) public roles;
    mapping(TokenOpTypes.OpType => uint256) public requiredSignatures;

    mapping(bytes32 => mapping(uint256 => bool)) public signatures;
    mapping(bytes32 => uint256) public signatureCount;
    mapping(bytes32 => bool) public usedHashes;

    event SignatureValidated(
        address operator,
        TokenOpTypes.OpType operationType,
        bytes32 operationMessageHash,
        bytes[] signatures
    );
    event SignatureReceived(address signer, bytes32 hash, uint256 roleIndex);
    event RoleAdded(string roleName, address signerAddress);
    event SignerUpdated(uint256 roleIndex, address newSigner);

    constructor(
        address _authorizationGuardAddress,
        SignerEntity[] memory _mintSigners,
        SignerEntity[] memory _releaseSigners
    ) {
        __AuthorizationGuardAccess_init(_authorizationGuardAddress);

        /// Setup mint signers
        for (uint8 i = 0; i < _mintSigners.length; i++) {
            requiredSignatures[TokenOpTypes.OpType.MINT_OP]++;
            addRole(
                _mintSigners[i].roleName,
                _mintSigners[i].signerAddress,
                TokenOpTypes.OpType.MINT_OP
            );
        }
        /// Setup release signers
        for (uint8 i = 0; i < _releaseSigners.length; i++) {
            requiredSignatures[TokenOpTypes.OpType.RELEASE_OP]++;
            addRole(
                _releaseSigners[i].roleName,
                _releaseSigners[i].signerAddress,
                TokenOpTypes.OpType.RELEASE_OP
            );
        }
    }

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

    function getMessageHashBurn(
        string memory functionName,
        TokenOpTypes.BurnTokenOpWithSignature memory message
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(functionName, message.weight, message.metalId));
    }

    function verifyCommonOpSignature(
        string memory functionName,
        TokenOpTypes.OpType operationType,
        TokenOpTypes.CommonTokenOpWithSignature memory message
    ) external onlyTrustedContracts returns (bool) {
        bytes32 _hash = getMessageHashCommon(
            functionName,
            TokenOpTypes.CommonTokenOpSignatureData({
                account: message.account,
                weight: message.weight,
                metalId: message.metalId,
                documentHash: message.documentHash
            })
        );
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        require(prefixedHash == message.signatureHash, "Invalid hash");

        bool isValid = validateSignatures(
            prefixedHash,
            message.signatures,
            message.roleIndices,
            operationType
        );

        // Ensure that the validation was successful
        require(isValid, "Invalid signatures");

        return true;
    }

    function validateSignatures(
        bytes32 _hash,
        bytes[] memory signaturesArray,
        uint256[] memory roleIndices,
        TokenOpTypes.OpType operationType
    ) internal returns (bool) {
        require(
            signaturesArray.length == requiredSignatures[operationType],
            "Not enough signatures"
        );
        require(
            signaturesArray.length == roleIndices.length,
            "Mismatching signature and roles length"
        );
        require(!usedHashes[_hash], "Hash has already been used for minting");

        for (uint256 i = 0; i < signaturesArray.length; i++) {
            address signer = recoverSigner(_hash, signaturesArray[i]);
            uint256 roleIndex = roleIndices[i];
            require(isSignerRole(signer, roleIndex, operationType), "Invalid signer for role");
            require(!signatures[_hash][roleIndex], "Signature for role already used");

            signatures[_hash][roleIndex] = true;
            signatureCount[_hash]++;

            emit SignatureReceived(signer, _hash, roleIndex);
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

    function isSigner(
        address _address,
        TokenOpTypes.OpType operationType
    ) public view returns (bool) {
        for (uint256 i = 0; i < roles[operationType].length; i++) {
            if (roles[operationType][i].signerAddress == _address) {
                return true;
            }
        }
        return false;
    }

    function isSignerRole(
        address _address,
        uint256 roleIndex,
        TokenOpTypes.OpType operationType
    ) public view returns (bool) {
        require(roleIndex < roles[operationType].length, "Invalid role index");
        return roles[operationType][roleIndex].signerAddress == _address;
    }

    function recoverSigner(bytes32 _hash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        return messageDigest.recover(signature);
    }

    function addRole(
        string memory roleName,
        address signerAddress,
        TokenOpTypes.OpType operationType
    ) public onlyAdminAccess {
        roles[operationType].push(Role(roleName, signerAddress));
        emit RoleAdded(roleName, signerAddress);
    }

    function updateSigner(
        uint256 roleIndex,
        address newSigner,
        TokenOpTypes.OpType operationType
    ) public onlyAdminAccess {
        require(roleIndex < roles[operationType].length, "Invalid role index");
        require(!isSigner(newSigner, operationType), "New signer is already a signer");

        roles[operationType][roleIndex].signerAddress = newSigner;
        emit SignerUpdated(roleIndex, newSigner);
    }

    function getRoles(TokenOpTypes.OpType operationType) public view returns (Role[] memory) {
        return roles[operationType];
    }
}
