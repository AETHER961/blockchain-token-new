// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract MultiSigApproval {
    // Roles
    address public warehouseAdmin;
    address public tokenManager;
    address public director;
    address public director2;
    address public tokenManagerAdmin;
    address public auditor;

    // Signature batches
    address[] public firstBatchSigners;
    address[] public secondBatchSigners;

    constructor(
        address _warehouseAdmin,
        address _tokenManager,
        address _director,
        address _director2,
        address _tokenManagerAdmin,
        address _auditor
    ) {
        warehouseAdmin = _warehouseAdmin;
        tokenManager = _tokenManager;
        director = _director;
        director2 = _director2;
        tokenManagerAdmin = _tokenManagerAdmin;
        auditor = _auditor;

        firstBatchSigners.push(warehouseAdmin);
        firstBatchSigners.push(tokenManager);
        firstBatchSigners.push(director);
        firstBatchSigners.push(director2);

        secondBatchSigners.push(tokenManager);
        secondBatchSigners.push(tokenManagerAdmin);
        secondBatchSigners.push(auditor);
    }

    function verifySignatures(
        bytes32 hash,
        bytes[] memory signatures,
        address[] memory signers
    ) internal pure returns (bool) {
        require(signatures.length == signers.length, "Mismatched signatures and signers length");

        for (uint256 i = 0; i < signers.length; i++) {
            address signer = recoverSigner(hash, signatures[i]);
            require(signer == signers[i], "Invalid signature");
        }
        return true;
    }

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function getFirstBatchSigners() external view returns (address[] memory) {
        return firstBatchSigners;
    }

    function getSecondBatchSigners() external view returns (address[] memory) {
        return secondBatchSigners;
    }
}
