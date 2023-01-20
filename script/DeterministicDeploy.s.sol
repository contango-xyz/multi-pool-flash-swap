// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "src/FlashSwapper.sol";

contract DeterministicDeploy is Script {
    address internal constant DETERMINISTIC_CREATE2_FACTORY = 0x7A0D94F55792C434d74a40883C6ed8545E406D12;

    function run() public returns (FlashSwapper flashSwapper) {
        vm.startBroadcast();
        bytes memory creationBytecode = type(FlashSwapper).creationCode;
        (bool success, bytes memory returnData) = DETERMINISTIC_CREATE2_FACTORY.call(creationBytecode);
        require(success, "DeterministicDeploy: failed to deploy");
        flashSwapper = FlashSwapper(address(uint160(bytes20(returnData))));
        vm.stopBroadcast();
    }
}
