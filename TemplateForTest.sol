 pragma solidity ^ 0.5.12;


contract ERC20Token {
    function balanceOf(address) public view returns(uint);
    function allowance(address, address) public view returns(uint);
    function transfer(address, uint) public returns(bool);
    function approve(address, uint)  public returns(bool);
    function transferFrom(address, address, uint) public returns(bool);
}


contract TokenSaverTest {

    address public owner;
    address public reserveAddress;
    address private backendAddress;
    uint public endTimestamp;
    address[] public tokenType;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyBackend(){
        require(msg.sender == backendAddress);
        _;
    }

    event TokensToSave(address tokenToSave);
    event SelfdestructionEvent(bool status);
    event TransactionInfo(address tokenType, uint succeededAmount);

    constructor(address _ownerAddress, address _reserveAddress, uint _endTimestamp) public {
        require(_ownerAddress != address(0),"Invalid OWNER address");
        require(_reserveAddress != address(0),"Invalid RESERVE address");
        require(_endTimestamp > now, "Invalid TIMESTAMP");
        owner = _ownerAddress;
        backendAddress = msg.sender;
        reserveAddress = _reserveAddress;
        endTimestamp = _endTimestamp;
    }

    function addTokenType(address[] memory _tokenAddressArray) public onlyBackend returns(bool) {

        for (uint x = 0; x < _tokenAddressArray.length ; x++ ) {
            for (uint z = 0; z < tokenType.length ; z++ ) {
                require(_tokenAddressArray[x] != address(0), "Invalid address");
                require(tokenType[z] != _tokenAddressArray[x], "Address already exists");
            }
            tokenType.push(_tokenAddressArray[x]);
            emit TokensToSave(_tokenAddressArray[x]);
        }

        require(tokenType.length <= 30, "Max 30 types allowed");
        return true;
    }

    function getBalance(address _tokenAddress, address _owner) private view returns(uint){
        return ERC20Token(_tokenAddress).balanceOf(_owner);
    }

    function tryGetResponse(address _tokenAddress) public returns(bool) {
        bool success;
        bytes memory result;
        (success, result) = address(_tokenAddress).call(abi.encodeWithSignature("balanceOf(address)", owner));
        if ((success) && (result.length > 0)) {return true;}
        else {return false;}
    }

    function getAllowance(address _tokenAddress) private view returns(uint){
        return ERC20Token(_tokenAddress).allowance(owner, address(this));
    }

    function transferFromOwner(address _tokenAddress, uint _amount) private returns(bool){
        ERC20Token(_tokenAddress).transferFrom(owner, reserveAddress, _amount);
        return true;
    }

    function() external {

        require(now > endTimestamp, "Invalid execution time");
        uint balance;
        uint allowed;
        uint balanceContract;

        for (uint l = 0; l < tokenType.length; l++) {
            bool success;
            success = tryGetResponse(tokenType[l]);

            if (success) {
                allowed = getAllowance(tokenType[l]);
                balance = getBalance(tokenType[l], owner);
                balanceContract = getBalance(tokenType[l], address(this));

                if ((balanceContract != 0)) {
                    ERC20Token(tokenType[l]).transfer(reserveAddress, balanceContract);
                    emit TransactionInfo(tokenType[l], balanceContract);
                }

                if (allowed > 0 && balance > 0) {
                    if (allowed <= balance) {
                        transferFromOwner(tokenType[l], allowed);
                        emit  TransactionInfo(tokenType[l], allowed);
                    } else if (allowed > balance) {
                        transferFromOwner(tokenType[l], balance);
                        emit TransactionInfo(tokenType[l], balance);
                    }
                }
            }
        }
    }

    function selfdestruction() public onlyOwner{
        emit SelfdestructionEvent(true);
        selfdestruct(address(0));
    }

}