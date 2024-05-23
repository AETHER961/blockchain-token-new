// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/**
 * @title ArrayUtils
 * @author
 * @dev Utility library of inline array functions
 */
library ArrayUtils {
    /// @dev Returns uint256 array of a `length` items with a value of `element`
    /// @param element Element to fill the array with
    /// @param length Length of the array
    /// @return array Array containing `element`
    function asUint256Array(
        uint256 length,
        uint256 element
    ) internal pure returns (uint256[] memory array) {
        array = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            array[i] = element;
        }
    }

    /// @dev Returns addresses array of a `length` items with a value of `element`
    /// @param element Element to fill the array with
    /// @param length Length of the array
    /// @return array Array containing `element`
    function asAddressArray(
        uint256 length,
        address element
    ) internal pure returns (address[] memory array) {
        array = new address[](length);

        for (uint256 i; i < length; ++i) {
            array[i] = element;
        }
    }

    /// @dev Returns uint8 array of a `length` items with a value of `element`
    /// @param element Element to fill the array with
    /// @param length Length of the array
    /// @return array Array containing `element`
    function asUint8Array(
        uint256 length,
        uint8 element
    ) internal pure returns (uint8[] memory array) {
        array = new uint8[](length);

        for (uint256 i; i < length; ++i) {
            array[i] = element;
        }
    }

    /// @dev Merges two-dimensional array of uint256 into one-dimensional array
    /// @param arrays Two-dimensional array of uint256
    /// @return mergedArray One-dimensional array of uint256
    function mergeUint256Arrays(
        uint256[][] calldata arrays
    ) internal pure returns (uint256[] memory mergedArray) {
        uint256 mergedLength;
        for (uint256 i; i < arrays.length; ++i) mergedLength += arrays[i].length;

        uint256 index;
        mergedArray = new uint256[](mergedLength);
        for (uint256 i; i < arrays.length; ++i) {
            for (uint256 j; j < arrays[i].length; ++j) {
                unchecked {
                    mergedArray[index] = arrays[i][j];
                    ++index;
                }
            }
        }
    }
}
