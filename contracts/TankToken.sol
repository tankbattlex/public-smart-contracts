pragma solidity ^0.8.5;

import "./erc20/ERC20Burnable.sol";
import "./util/SafeMath.sol";
import "./interface/IUniswapV2Factory.sol";
import "./core/AccessControl.sol";

contract TankToken is AccessControl, ERC20Burnable {
    using SafeMath for uint256;
    bytes32 public constant GAME_ADMIN_ROLE = keccak256("GAME_ADMIN");
    bytes32 public constant BURN_ROLE = keccak256("BURN");

    // ############
    // Initializer
    // ############
    constructor() ERC20("TankBattle Token", "TBL") {
        _mint(msg.sender, 1000000000 * 10**18);
        AccessControl_init();
    }

    address private uniswapV2Pair;
    address private taxAddress;
    //Sell & buy fee on PancakeSwap
    uint256 private sellFeeRate;
    uint256 private buyFeeRate;

    mapping(address => bool) private usersBanned;
    mapping(address => bool) private bots;
    bool private antiBotEnable;
    uint256 private antiBotTime;
    uint256 private antiBotAmount;

    // ############
    // Internal
    // ############
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override userNotBanned {
        if (
            antiBotTime > block.timestamp &&
            amount > antiBotAmount &&
            bots[sender]
        ) {
            revert("Anti bot enable!");
        }
        uint256 transferFeeRate = recipient == uniswapV2Pair
            ? sellFeeRate
            : (sender == uniswapV2Pair ? buyFeeRate : 0);
        if (
            transferFeeRate > 0 &&
            sender != address(this) &&
            recipient != address(this)
        ) {
            uint256 _fee = amount.mul(transferFeeRate).div(100);
            super._transfer(sender, taxAddress, _fee);
            amount = amount.sub(_fee);
        }
        super._transfer(sender, recipient, amount);
    }

    // ############
    // Admin functions
    // ############

    function burn(uint256 amount) public override onlyCEO {
        _burn(_msgSender(), amount);
    }

    function setRouterAddress(address newRouter) public onlyGM {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }

    function setTaxAddress(address newTaxAddress) public onlyGM {
        taxAddress = newTaxAddress;
    }

    function enableAntiBot(uint256 _amount) external onlyGM {
        require(_amount > 0, "not accept 0 value");
        require(!antiBotEnable);
        antiBotAmount = _amount;
        antiBotTime = block.timestamp.add(15 minutes);
        antiBotEnable = true;
    }

    function disableAntiBot() external onlyGM {
        antiBotEnable = false;
    }

    function setFee(uint256 _sellFeeRate, uint256 _buyFeeRate) public onlyGM {
        require(_sellFeeRate <= 10, "Max 10%");
        require(_buyFeeRate <= 10, "Max 10%");
        sellFeeRate = _sellFeeRate;
        buyFeeRate = _buyFeeRate;
    }

    function banUser(address user, bool to) external onlyGM {
        usersBanned[user] = to;
    }

    function banUsers(address[] calldata users, bool to) external onlyGM {
        for (uint256 i = 0; i < users.length; i++) {
            usersBanned[users[i]] = to;
        }
    }

    function setBots(address _bot) external onlyGM {
        require(!bots[_bot]);
        bots[_bot] = true;
    }

    // ############
    // Public views
    // ############
    function sellFee() public view returns (uint256) {
        return sellFeeRate;
    }

    function buyFee() public view returns (uint256) {
        return buyFeeRate;
    }

    // ############
    // Modifiers
    // ############

    modifier userNotBanned() {
        require(usersBanned[msg.sender] == false, "Access forbidden!");
        _;
    }
}
