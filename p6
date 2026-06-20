// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 { 
    function balanceOf(address account) external view returns (uint256); 
}

contract AerodromeEthPoolTracker { 
    // Oficjalny adres puli vAMM-WETH/USDC na sieci Base
    address public immutable AERODROME_POOL;
    address public immutable WETH = 0x4200000000000000000000000000000000000006;

    // Adres właściciela kontraktu (Twój bot / Twój portfel)
    address public owner;

    // Statystyki przepływów
    uint256 public totalEthInTracked;   // Łączny napływ WETH do puli
    uint256 public totalEthOutTracked;  // Łączny odpływ WETH z puli
    uint256 public lastCheckBalance;    // Ostatnio zanotowany stan puli

    // Definicje zdarzeń (Events) dla bota i systemów analitycznych
    event PoolEthFlowInRecorded(uint256 amountIn, uint256 currentPoolBalance);
    event PoolEthFlowOutRecorded(uint256 amountOut, uint256 currentPoolBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modyfikator dostępu - blokuje niepowołane adresy
    modifier onlyOwner() {
        require(msg.sender == owner, "Blad: Tylko wlasciciel moze wywolac te funkcje");
        _;
    }

    constructor(address _aerodromePool) {
        require(_aerodromePool != address(0), "Adres puli nie moze byc zerowy");
        AERODROME_POOL = _aerodromePool;
        owner = msg.sender; // Osoba wdrażająca staje się właścicielem
        lastCheckBalance = IERC20(WETH).balanceOf(_aerodromePool);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Funkcja monitoruje, zlicza i kategoryzuje realny ruch WETH w puli płynności.
     * @dev Dostępna tylko dla właściciela (bota). Wywołuj ją okresowo, aby aktualizować statystyki.
     */
    function updateEthFlow() public onlyOwner returns (uint256, uint256) {
        uint256 currentBalance = IERC20(WETH).balanceOf(AERODROME_POOL);
        
        if (currentBalance > lastCheckBalance) {
            // Sytuacja A: Balans wzrósł -> Napływ WETH do puli (Kupno USDC za WETH / Dodanie płynności)
            uint256 flowIn = currentBalance - lastCheckBalance;
            totalEthInTracked += flowIn;
            emit PoolEthFlowInRecorded(flowIn, currentBalance);
            
        } else if (currentBalance < lastCheckBalance) {
            // Sytuacja B: Balans spadł -> Odpływ WETH z puli (Sprzedaż USDC za WETH / Wycofanie płynności)
            uint256 flowOut = lastCheckBalance - currentBalance;
            totalEthOutTracked += flowOut;
            emit PoolEthFlowOutRecorded(flowOut, currentBalance);
        }

        lastCheckBalance = currentBalance;
        return (totalEthInTracked, totalEthOutTracked);
    }

    /**
     * @notice Zwraca aktualny bilans netto (różnicę między historycznym napływem a odpływem).
     */
    function getNetEthFlow() public view returns (int256) {
        return int256(totalEthInTracked) - int256(totalEthOutTracked);
    }

    /**
     * @notice Pobiera aktualny, prawdziwy balans WETH zablokowany w puli płynności.
     */
    function getPoolWethBalance() public view returns (uint256) {
        return IERC20(WETH).balanceOf(AERODROME_POOL);
    }

    /**
     * @notice Pozwala na bezpieczne przeniesienie własności kontraktu (np. na adres dedykowanego bota).
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Nowy wlasciciel nie moze byc adresem zerowym");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
