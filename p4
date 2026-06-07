// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 { 
    function balanceOf(address account) external view returns (uint256); 
}

contract AerodromeEthPoolTracker { 
    // Oficjalny adres puli vAMM-WETH/USDC na sieci Base
    // To tutaj fizycznie znajdują się tokeny WETH, a nie na routerze!
    address public immutable AERODROME_POOL = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43; // TODO: Upewnij się, że to adres puli, a nie routera
    address public immutable WETH = 0x4200000000000000000000000000000000000006;

    uint256 public totalEthTracked;
    uint256 public lastCheckBalance;

    // Zmieniono nazwę eventu na bardziej adekwatną dla puli
    event PoolEthFlowRecorded(uint256 amountIn, uint256 currentPoolBalance);

    constructor(address _aerodromePool) {
        // Podaj poprawny adres puli vAMM WETH/USDC podczas wdrożenia
        AERODROME_POOL = _aerodromePool;
        lastCheckBalance = IERC20(WETH).balanceOf(_aerodromePool);
    }

    /**
     * @notice Funkcja monitoruje i zlicza realny napływ WETH do puli płynności.
     * @dev Wywołuj ją okresowo (np. przez bota lub Chainlink Automation), aby rejestrować zmiany.
     */
    function updateEthFlow() public returns (uint256) {
        uint256 currentBalance = IERC20(WETH).balanceOf(AERODROME_POOL);
        
        // Jeśli balans wzrósł, ktoś wpłacił WETH do puli (kupił USDC za WETH lub dodał płynność)
        if (currentBalance > lastCheckBalance) {
            uint256 flowIn = currentBalance - lastCheckBalance;
            totalEthTracked += flowIn;
            emit PoolEthFlowRecorded(flowIn, currentBalance);
        }

        lastCheckBalance = currentBalance;
        return totalEthTracked;
    }

    /**
     * @notice Pobiera aktualny, prawdziwy balans WETH zablokowany w puli płynności.
     */
    address public immutable AERODROME_POOL;
    function getPoolWethBalance() public view returns (uint256) {
        return IERC20(WETH).balanceOf(AERODROME_POOL);
    }
}
