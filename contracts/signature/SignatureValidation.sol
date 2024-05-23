// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// import {AuthorizationGuard} from "../management/roles/AuthorizationGuard.sol";
import {AuthorizationGuardAccess} from "../management/roles/AuthorizationGuardAccess.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
    * Deploy this contract second.
    * Pass to the constructor the number of required signatures and the authorization guard address.

 */
contract MultiSigValidation is AuthorizationGuardAccess {
    using ECDSA for bytes32;

    struct Role {
        string name;
        address signerAddress;
    }

    Role[] public roles;
    uint256 public requiredSignatures;

    // AuthorizationGuard private authorizationGuard;

    // uint256 public tokensToMint;
    mapping(bytes32 => mapping(uint256 => bool)) public signatures;
    mapping(bytes32 => uint256) public signatureCount;
    mapping(bytes32 => bool) public usedHashes;

    event TokensMinted(address operator, uint256 amount);
    event SignatureReceived(address signer, bytes32 hash, uint256 roleIndex);
    event RoleAdded(string roleName, address signerAddress);
    event SignerUpdated(uint256 roleIndex, address newSigner);

    modifier onlySigner() {
        require(isSigner(msg.sender), "Not a signer");
        _;
    }

    constructor(
        uint256 _requiredSignatures,
        address _authorizationGuardAddress,
        address[] memory _signers,
        string[] memory _roleNames
    ) {
        requiredSignatures = _requiredSignatures;
        __AuthorizationGuardAccess_init(_authorizationGuardAddress);

        require(_signers.length == _roleNames.length, "Mismatching signers and roles lengths");

        /// Setup signers
        for (uint8 i = 0; i < _signers.length; i++) {
            addRole(_roleNames[i], _signers[i]);
        }
    }

    function validateSignatures(
        bytes32 _hash,
        bytes[] memory signaturesArray,
        uint256[] memory roleIndices
    ) public onlyAuthorizedAccess returns (bool) {
        require(signaturesArray.length == requiredSignatures, "Not enough signatures");
        require(!usedHashes[_hash], "Hash has already been used for minting");

        for (uint256 i = 0; i < signaturesArray.length; i++) {
            address signer = recoverSigner(_hash, signaturesArray[i]);
            uint256 roleIndex = roleIndices[i];
            require(isSignerRole(signer, roleIndex), "Invalid signer for role");
            require(!signatures[_hash][roleIndex], "Signature for role already used");

            signatures[_hash][roleIndex] = true;
            signatureCount[_hash]++;

            emit SignatureReceived(signer, _hash, roleIndex);
        }

        require(signatureCount[_hash] >= requiredSignatures, "Not enough valid signatures");

        // Mark the hash as used
        usedHashes[_hash] = true;

        return true;
    }

    function isSigner(address _address) public view returns (bool) {
        for (uint256 i = 0; i < roles.length; i++) {
            if (roles[i].signerAddress == _address) {
                return true;
            }
        }
        return false;
    }

    function isSignerRole(address _address, uint256 roleIndex) public view returns (bool) {
        require(roleIndex < roles.length, "Invalid role index");
        return roles[roleIndex].signerAddress == _address;
    }

    function recoverSigner(bytes32 _hash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
        );
        return messageDigest.recover(signature);
    }

    function addRole(string memory roleName, address signerAddress) public onlyAdminAccess {
        roles.push(Role(roleName, signerAddress));
        emit RoleAdded(roleName, signerAddress);
    }

    function updateSigner(uint256 roleIndex, address newSigner) public onlyAdminAccess {
        require(roleIndex < roles.length, "Invalid role index");
        require(!isSigner(newSigner), "New signer is already a signer");

        roles[roleIndex].signerAddress = newSigner;
        emit SignerUpdated(roleIndex, newSigner);
    }

    function getRoles() public view returns (Role[] memory) {
        return roles;
    }
}
