// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TitheManager (Worldview-Agnostic Version)
 * @dev Generalized tithing / charitable redirection contract.
 *      Supports multiple presets for different worldviews:
 *      - Christian tithe: 10% (default)
 *      - Muslim Zakat: 2.5%
 *      - Secular / voluntary donation: variable (owner or governance set)
 *      - Jewish Tzedakah: traditionally 10% or more, configurable
 *      - Custom / inter-faith pool
 *
 *      Fully adjustable at runtime. Designed for easy integration with
 *      PilotEscrow.closeCampaign() and future DAO governance.
 *
 *      This version is deliberately faith-agnostic: the contract does not
 *      enforce any religious rule — it simply provides convenient presets
 *      and a clean mechanism to redirect a percentage of value to
 *      designated recipients (EOAs, other contracts, or a council treasury).
 */
contract TitheManager is Ownable {
    // === PRESETS (basis points: 10000 = 100%) ===
    uint256 public constant PRESET_CHRISTIAN_TITHE = 1000;   // 10%
    uint256 public constant PRESET_ZAKAT          = 250;     // 2.5%
    uint256 public constant PRESET_TZEDAKAH       = 1000;    // 10% (common Jewish benchmark)
    uint256 public constant PRESET_SECULAR        = 500;     // 5% example

    uint256 public titheBps = PRESET_CHRISTIAN_TITHE; // Current active rate

    // Recipients & weighting (same as before, fully flexible)
    address[] public recipients;
    mapping(address => uint256) public sharesBps;
    uint256 public totalSharesBps;

    // Optional: label for current preset (for UI / events)
    string public currentPresetLabel = "christian-tithe-10pct";

    event TitheRateUpdated(uint256 newBps, string presetLabel);
    event RecipientAdded(address indexed recipient, uint256 shareBps);
    event RecipientRemoved(address indexed recipient);
    event TitheDistributed(uint256 totalAmount, uint256 redirectedAmount, address mainRecipient);

    constructor() Ownable(msg.sender) {}

    // === PRESET FUNCTIONS (one-call convenience) ===
    function useChristianTithe() external onlyOwner {
        _setRate(PRESET_CHRISTIAN_TITHE, "christian-tithe-10pct");
    }

    function useZakat() external onlyOwner {
        _setRate(PRESET_ZAKAT, "zakat-2.5pct");
    }

    function useTzedakah() external onlyOwner {
        _setRate(PRESET_TZEDAKAH, "tzedakah-10pct");
    }

    function useSecular(uint256 customBps) external onlyOwner {
        require(customBps <= 10000, "Invalid custom rate");
        _setRate(customBps, "secular-custom");
    }

    function setCustomRate(uint256 newBps, string calldata label) external onlyOwner {
        require(newBps <= 10000, "Rate cannot exceed 100%");
        _setRate(newBps, label);
    }

    function _setRate(uint256 newBps, string memory label) internal {
        titheBps = newBps;
        currentPresetLabel = label;
        emit TitheRateUpdated(newBps, label);
    }

    // === RECIPIENT MANAGEMENT (unchanged, battle-tested) ===
    function addRecipient(address recipient, uint256 shareBps) external onlyOwner {
        require(recipient != address(0), "Zero address");
        require(shareBps > 0 && shareBps <= 10000, "Invalid share");

        if (sharesBps[recipient] == 0) {
            recipients.push(recipient);
        }
        totalSharesBps = totalSharesBps - sharesBps[recipient] + shareBps;
        sharesBps[recipient] = shareBps;

        emit RecipientAdded(recipient, shareBps);
    }

    function removeRecipient(address recipient) external onlyOwner {
        require(sharesBps[recipient] > 0, "Not a recipient");
        totalSharesBps -= sharesBps[recipient];
        sharesBps[recipient] = 0;
        emit RecipientRemoved(recipient);
    }

    // === CORE DISTRIBUTION (same logic, now used by any worldview) ===
    function distribute(uint256 totalAmount, address mainRecipient) external payable {
        require(msg.value == totalAmount, "Value mismatch");
        require(mainRecipient != address(0), "Invalid main recipient");

        uint256 redirectAmount = (totalAmount * titheBps) / 10000;
        uint256 netAmount = totalAmount - redirectAmount;

        if (redirectAmount > 0 && recipients.length > 0 && totalSharesBps > 0) {
            for (uint256 i = 0; i < recipients.length; i++) {
                address r = recipients[i];
                uint256 share = sharesBps[r];
                if (share > 0) {
                    uint256 amt = (redirectAmount * share) / totalSharesBps;
                    if (amt > 0) {
                        (bool ok, ) = payable(r).call{value: amt}("");
                        require(ok, "Redirect transfer failed");
                    }
                }
            }
        } else if (redirectAmount > 0) {
            // Fallback to owner (or could be a council treasury)
            (bool ok, ) = payable(owner()).call{value: redirectAmount}("");
            require(ok, "Fallback redirect failed");
        }

        if (netAmount > 0) {
            (bool ok, ) = payable(mainRecipient).call{value: netAmount}("");
            require(ok, "Net transfer failed");
        }

        emit TitheDistributed(totalAmount, redirectAmount, mainRecipient);
    }

    receive() external payable {}
}
