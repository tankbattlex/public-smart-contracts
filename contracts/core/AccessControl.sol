pragma solidity ^0.8.5;

contract AccessControl {
    address public ceoAddress;
    address public cfoAddress;
    address public gmAddress;

    function AccessControl_init() internal {
        ceoAddress = msg.sender;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyGM() {
        require(msg.sender == gmAddress);
        _;
    }

    modifier onlyCLevel() {
        require(msg.sender == ceoAddress || msg.sender == cfoAddress);
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    function setGM(address _newGM) external onlyCEO {
        require(_newGM != address(0));
        gmAddress = gmAddress;
    }

    function withdrawBalance() external onlyCFO {
        address payable _cfo = payable(cfoAddress);
        _cfo.transfer(address(this).balance);
    }
}
