// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address account) external view return (uint256);
}

contract AerodromeEthTracker {
    // Oficjalne adresy na sieci Base
    address public constant AERODROME_ROUTER = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address public constant WETH = 0x4200000000000000000000000000000000000006;

    uint256 public totalEthTracked;
    uint256 public lastCheckBalance;

    event EthFlowRecorded(uint256 amountIn, uint256 currentRouterBalance);

    constructor() {
        // Inicjalizacja początkowego balansu routera
        lastCheckBalance = IERC20(WETH).balanceOf(AERODROME_ROUTER);
    }

    /**
     * @notice Funkcja aktualizuje i zlicza napływ WETH na router Aerodrome.
     * @dev Powinna być wywoływana okresowo (np. przez Keepers) lub przy analityce.
     */
    function updateEthFlow() public returns (uint256) {
        uint256 currentBalance = IERC20(WETH).balanceOf(AERODROME_ROUTER);
        
        // Jeśli balans wzrósł, oznacza to napływ ETH (swap lub dodanie płynności)
        if (currentBalance > lastCheckBalance) {
            uint256 flowIn = currentBalance - lastCheckBalance;
            totalEthTracked += flowIn;
            emit EthFlowRecorded(flowIn, currentBalance);
        }

        lastCheckBalance = currentBalance;
        return totalEthTracked;
    }

    /**
     * @notice Pobiera aktualny balans WETH bezpośrednio na routerze Aerodrome.
     */
    function getRouterWethBalance() public view returns (uint256) {
        return IERC20(WETH).balanceOf(AERODROME_ROUTER);
    }
}
