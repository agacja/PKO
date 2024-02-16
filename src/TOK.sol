pragma solidity ^0.8.18;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract TOK is PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant ALL = 0;
    uint256 private constant TOKEN = 1;
    uint256 private constant ORDER = 2;
    IERC20Upgradeable private coinToken;

    enum State {
        Created,
        OwnerApproved,
        PpraApproved,
        Hidden,
        Done,
        Removed,
        OrderOwnerCancelled,
        TokenOwnerCancelled,
        OrderOwnerChanged
    }

    struct Order {
        uint256 pricePerToken;
        address tokenAddress;
        uint256 totalOrderAmount;
        State currentState;
        bool ppraFee;
        address equityTokenOwner;
        uint256 equityTokenAmount;
        bool equityTokenSig;
        bool stableCoinSig;
    }

    function getOrders(uint256 _orderId)
        external
        view
        returns (
            uint256 price,
            address tokenAddress,
            State currentState,
            uint256 amount,
            bool ppraFee,
            address equityTokenOwner,
            uint256 equityTokenAmount
        )
    {
        return (
            orders[_orderId].pricePerToken,
            orders[_orderId].tokenAddress,
            orders[_orderId].currentState,
            orders[_orderId].totalOrderAmount,
            orders[_orderId].ppraFee,
            orders[_orderId].equityTokenOwner,
            orders[_orderId].equityTokenAmount
        );
    }

    Order[] private orders;
    mapping(address => uint256) private stableCoinBalance;
    mapping(address => uint256) private equityTokenOwnerShipAmount;
    mapping(uint256 => address) private orderToOwner;

    uint256 public totalFee;

    event NewOrderEvent(
        uint256 indexed orderId,
        uint256 indexed totalOrderAmount,
        address indexed tokenAddress,
        uint256 tokenAmount
    );

    event CancelOrderByOwnerEvent(
        address indexed tokenAddress,
        uint256 indexed orderId
    );

    event RunCancelOrderByOwnerEvent(
        address indexed tokenAddress,
        uint256 indexed orderId
    );

    event CancelOrderByTokenOwnerEvent(
        address indexed tokenAddress,
        uint256 indexed orderId
    );

    event RunCancelOrderByTokenOwnerEvent(
        address indexed tokenAddress,
        uint256 indexed orderId
    );

    event RunModifyOrderByPpraEvent(
        address indexed tokenAddress,
        uint256 indexed orderId,
        uint256 indexed mode
    );

    event TransactEvent(
        address tokenAddress,
        uint256 indexed orderId,
        address indexed tokenOwner,
        address indexed newOwner,
        bool ppraFee,
        uint256 totalOrderAmount,
        uint256 fee
    );

    event DepositEquityTokenEvent(
        uint256 indexed orderId,
        address indexed clientAddress,
        uint256 indexed depositTokenAmount
    );

    event LockTransactionEvent(uint256 indexed orderId);

    event ChangeOrderByOwnerEvent(
        address indexed tokenAddress,
        uint256 indexed pricePerToken,
        uint256 indexed totalOrderAmount
    );

    event RunChangeOrderByOwnerEvent(uint256 indexed orderId);

    modifier onlyOrderOwner(uint256 _orderId) {
        require(
            msg.sender == orderToOwner[_orderId],
            "TOK: you are not Order owner"
        );
        _;
    }

    modifier onlyEquityTokenOwner(uint256 _orderId) {
        require(
            msg.sender == orders[_orderId].equityTokenOwner,
            "TOK: you are not Token owner"
        );
        _;
    }

    modifier onlyValidState(uint _orderId, State _state) {
        require(orders[_orderId].currentState == _state, "TOK: state error");
        _;
    }

    modifier notPaused() {
        require(!paused(), "TOK: contract while paused");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function getOrderOwner(uint256 orderId) external view returns (address) {
        return orderToOwner[orderId];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getStableCoinBalance(address ownerAddress)
        external
        view
        returns (uint256)
    {
        return stableCoinBalance[ownerAddress];
    }

    function getEquityTokenOwnerShipAmount(address ownerAddress)
        external
        view
        returns (uint256)
    {
        return equityTokenOwnerShipAmount[ownerAddress];
    }

    function initialize(IERC20Upgradeable _coinAddress) public initializer {
        __Ownable_init();
        coinToken = _coinAddress;
    }

    function changeCoinTokenAddress(IERC20Upgradeable _coinAddress) public onlyOwner {
        coinToken = _coinAddress;
    }

    function createOrder(
        uint256 _price,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external notPaused {
        orders.push(
            Order(
                _price,
                _tokenAddress,
                _tokenAmount,
                State.Created,
                true,
                address(this),
                0,
                false,
                false
            )
        );
        uint orderId = orders.length - 1;
        orderToOwner[orderId] = msg.sender;
        uint256 totalOrderAmount = _tokenAmount * _price;
        deposit(coinToken, totalOrderAmount);

        emit NewOrderEvent(
            orderId,
            totalOrderAmount,
            _tokenAddress,
            _tokenAmount
        );
    }

    function cancelOrderByOwner(uint256 _orderId)
        external
        onlyOrderOwner(_orderId)
        onlyValidState(_orderId, State.Created)
        notPaused
    {
        orders[_orderId].currentState = State.OrderOwnerCancelled;

        emit CancelOrderByOwnerEvent(orders[_orderId].tokenAddress, _orderId);
    }

    function changeOrderByOwner(uint256 _orderId, address _tokenAddress)
        external
        onlyOrderOwner(_orderId)
        onlyValidState(_orderId, State.Created)
        notPaused
    {
        orders[_orderId].currentState = State.OrderOwnerChanged;
        orders[_orderId].tokenAddress = _tokenAddress;

        emit ChangeOrderByOwnerEvent(
            orders[_orderId].tokenAddress,
            orders[_orderId].pricePerToken,
            orders[_orderId].totalOrderAmount
        );
    }

    function runCancelOrderByOwner(uint256 _orderId) external {
        _runCancelOrderByOwner(_orderId);
    }

    function runChangeOrderByOwner(uint256 _orderId)
        external
        onlyOwner
        onlyValidState(_orderId, State.OrderOwnerChanged)
    {
        orders[_orderId].currentState = State.Created;

        emit RunChangeOrderByOwnerEvent(_orderId);
    }

    function _runCancelOrderByOwner(uint256 _orderId)
        internal
        onlyOwner
        onlyValidState(_orderId, State.OrderOwnerCancelled)
    {
        uint256 packageAmountPrice = orders[_orderId].totalOrderAmount * orders[_orderId].pricePerToken;
        address orderOwner = orderToOwner[_orderId];
        require(
            stableCoinBalance[orderOwner] >= packageAmountPrice,
            "TOK: insufficient balance"
        );
        stableCoinBalance[orderOwner] = stableCoinBalance[orderOwner] - packageAmountPrice;
        orders[_orderId].currentState = State.Removed;
        coinToken.safeTransfer(
            orderOwner,
            packageAmountPrice
        );

        emit RunCancelOrderByOwnerEvent(
            orders[_orderId].tokenAddress,
            _orderId
        );
    }

    function cancelOrderByTokenOwner(uint256 _orderId)
        external
        onlyEquityTokenOwner(_orderId)
        onlyValidState(_orderId, State.OwnerApproved)
        notPaused
    {
        orders[_orderId].currentState = State.TokenOwnerCancelled;

        emit CancelOrderByTokenOwnerEvent(
            orders[_orderId].tokenAddress,
            _orderId
        );
    }

    function runCancelOrderByTokenOwner(uint256 _orderId) external {
        _runCancelOrderByTokenOwner(_orderId);
    }

    function _runCancelOrderByTokenOwner(uint256 _orderId)
        internal
        onlyOwner
        onlyValidState(_orderId, State.TokenOwnerCancelled)
    {
        require(
            equityTokenOwnerShipAmount[orders[_orderId].equityTokenOwner] >=
                orders[_orderId].equityTokenAmount,
            "TOK: insufficient EquityToken amount"
        );
        require(
            orders[_orderId].equityTokenOwner != address(this),
            "TOK: contarct is a token owner"
        );
        equityTokenOwnerShipAmount[
            orders[_orderId].equityTokenOwner
        ] = equityTokenOwnerShipAmount[orders[_orderId].equityTokenOwner] - orders[_orderId].equityTokenAmount;
        orders[_orderId].currentState = State.Created;
        address equityTokenOwner = orders[_orderId].equityTokenOwner;
        orders[_orderId].equityTokenOwner = address(this);
        uint256 equityTokenAmount = orders[_orderId].equityTokenAmount;
        orders[_orderId].equityTokenAmount = 0;
        IERC20Upgradeable(orders[_orderId].tokenAddress).safeTransfer(
            equityTokenOwner,
            equityTokenAmount
        );

        emit RunCancelOrderByTokenOwnerEvent(
            orders[_orderId].tokenAddress,
            _orderId
        );
    }

    function runModifyOrderByPpra(uint256 _orderId, uint256 _mode)
        external
        onlyOwner
    {
        if (_mode == ALL) {
            _withdrawToken(_orderId);
            _withdrawOrder(_orderId);
        } else if (_mode == TOKEN) {
            _withdrawToken(_orderId);
        } else if (_mode == ORDER) {
            _withdrawOrder(_orderId);
        } else {
            _unlockTransaction(_orderId);
        }

        emit RunModifyOrderByPpraEvent(
            orders[_orderId].tokenAddress,
            _orderId,
            _mode
        );
    }

    function _withdrawOrder(uint256 _orderId) internal {
        require(
            orders[_orderId].currentState == State.Created,
            "TOK: order is not in Created state"
        );
        orders[_orderId].currentState = State.OrderOwnerCancelled;
        _runCancelOrderByOwner(_orderId);
    }

    function _withdrawToken(uint256 _orderId) internal {
        require(
            orders[_orderId].currentState == State.PpraApproved ||
                orders[_orderId].currentState == State.OwnerApproved,
            "TOK: order is not in PpraApproved or OwnerApproved state"
        );
        orders[_orderId].currentState = State.TokenOwnerCancelled;
        _runCancelOrderByTokenOwner(_orderId);
    }

    function _unlockTransaction(uint256 _orderId)
        internal
        onlyValidState(_orderId, State.PpraApproved)
    {
        orders[_orderId].currentState = State.OwnerApproved;
    }

    function transact(uint _orderId)
        external
        onlyValidState(_orderId, State.PpraApproved)
    {
        address newOwner = orderToOwner[_orderId];
        require(
            stableCoinBalance[newOwner] >= orders[_orderId].pricePerToken,
            "TOK: insufficient StableCoin balance"
        );
        require(
            equityTokenOwnerShipAmount[orders[_orderId].equityTokenOwner] >=
                orders[_orderId].equityTokenAmount,
            "TOK: insufficient EquityToken amount"
        );
        require(
            orders[_orderId].totalOrderAmount >=
                orders[_orderId].equityTokenAmount,
            "Insufficient EquityToken amount in order"
        );
        uint256 packageAmountPrice = orders[_orderId].equityTokenAmount * orders[_orderId].pricePerToken;
        stableCoinBalance[newOwner] = stableCoinBalance[newOwner] - packageAmountPrice;
        equityTokenOwnerShipAmount[
            orders[_orderId].equityTokenOwner
        ] = equityTokenOwnerShipAmount[orders[_orderId].equityTokenOwner] - orders[_orderId].equityTokenAmount;
        uint256 amount;
        uint fee;
        if (orders[_orderId].ppraFee) {
            amount = packageAmountPrice * 7 / 10;
            fee = packageAmountPrice - amount;
            totalFee = totalFee + fee;
        } else {
            amount = packageAmountPrice;
        }
        orders[_orderId].totalOrderAmount = orders[_orderId].totalOrderAmount - orders[_orderId].equityTokenAmount;
        if (orders[_orderId].totalOrderAmount == 0) {
            orders[_orderId].currentState = State.Done;
        } else {
            orders[_orderId].currentState = State.Created;
            orders[_orderId].ppraFee = true;
            orders[_orderId].equityTokenOwner = address(this);
            orders[_orderId].equityTokenAmount = 0;
        }
        //TOK -> Buyer
        IERC20Upgradeable(orders[_orderId].tokenAddress).safeTransfer(
            newOwner,
            orders[_orderId].equityTokenAmount
        );
        coinToken.safeTransfer(
            orders[_orderId].equityTokenOwner,
            amount
        );

        emit TransactEvent(
            orders[_orderId].tokenAddress,
            _orderId,
            orders[_orderId].equityTokenOwner,
            newOwner,
            orders[_orderId].ppraFee,
            amount,
            fee
        );
    }

    function lockTransaction(uint _orderId, bool _ppraFee)
        external
        onlyOwner
        onlyValidState(_orderId, State.OwnerApproved)
    {
        orders[_orderId].ppraFee = _ppraFee;
        orders[_orderId].currentState = State.PpraApproved;

        emit LockTransactionEvent(_orderId);
    }

    function deposit(IERC20Upgradeable _stableCoin, uint256 _amount) internal notPaused {
        stableCoinBalance[msg.sender] = stableCoinBalance[msg.sender] + _amount;

        _stableCoin.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function depositEquityToken(uint256 _orderId, uint256 _amount)
        public
        onlyValidState(_orderId, State.Created)
        notPaused
    {
        require(
            orders[_orderId].totalOrderAmount >= _amount,
            "TOK: EquityToken balance can not be bigger than order amount"
        );
        equityTokenOwnerShipAmount[msg.sender] = equityTokenOwnerShipAmount[msg.sender] + _amount;
        orders[_orderId].currentState = State.OwnerApproved;
        orders[_orderId].equityTokenOwner = msg.sender;
        orders[_orderId].equityTokenAmount = _amount;
        IERC20Upgradeable(orders[_orderId].tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit DepositEquityTokenEvent(_orderId, msg.sender, _amount);
    }
}
