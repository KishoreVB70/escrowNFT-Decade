// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract escrowNFT is Ownable {
    using SafeMath for uint256;

    // Declare state variables
    uint256 public fee;
    uint256 private escrowDigit = 16;
    uint256 private modulus = 10**escrowDigit;

    enum Status {
        Pending,
        Accepted,
        Rejected,
        Cancelled
    }

    struct Escrow {
        uint256 tokenId;
        uint256 paymentAmount;
        uint256 deadline;
        address tokenAddress;
        address buyerAddress;
        address sellerAddress;
        Status status;
    }

    mapping(uint256 => Escrow) public escrow;

    event NewEscrow(
        uint256 txId,
        uint256 tokenId,
        uint256 paymentAmount,
        address tokenAddress
    );

    event CancleEscrow(
        uint256 txId,
        uint256 tokenId,
        uint256 paymentAmount,
        address tokenAddress
    );

    event PayEscrow(
        uint256 txId,
        uint256 timestamp,
        uint256 tokenId,
        uint256 paymentAmount
    );

    modifier onlySeller(uint256 _txId) {
        require(
            msg.sender == escrow[_txId].sellerAddress,
            "Only seller can call this function"
        );
        _;
    }

    modifier onlyBuyer(uint256 _txId) {
        require(msg.sender == escrow[_txId].buyerAddress, "Only buyer can call this function");
        _;
    }

    constructor(uint256 _fee) {
        fee = _fee;
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function generateTxId(
        address _sellerAddress,
        address _buyerAddress,
        address _nftAddress,
        bytes memory _secret
    ) external view returns (uint256 txId) {
        txId =
            uint256(
                keccak256(
                    abi.encodePacked(
                        _sellerAddress,
                        _buyerAddress,
                        _nftAddress,
                        _secret
                    )
                )
            ) %
            modulus;
    }

    function createEscrow(
        uint256 _txId,
        uint256 _tokenId,
        uint256 _paymentAmount,
        address _tokenAddress,
        address _buyerAddress
    ) external {
        require(_paymentAmount > 0, "Payment amount must be greater than 0");
        require(_tokenAddress != address(0), "Token address cannot be 0x0");
        require(_buyerAddress != address(0), "Buyer address cannot be 0x0");
        IERC721 nft = IERC721(_tokenAddress);
        nft.transferFrom(msg.sender, address(this), _tokenId);
        escrow[_txId] = Escrow(
            _tokenId,
            _paymentAmount,
            block.timestamp + 1 days,
            _tokenAddress,
            _buyerAddress,
            msg.sender,
            Status.Pending
        );
        emit NewEscrow(_txId, _tokenId, _paymentAmount, _tokenAddress);
    }

    function cancleEscrow(uint256 _txId) external onlySeller(_txId) {
        require(
            block.timestamp > escrow[_txId].deadline,
            "Deadline not reached"
        );
        require(
            escrow[_txId].status == Status.Pending,
            "Escrow is not in pending status"
        );
        IERC721 nft = IERC721(escrow[_txId].tokenAddress);
        escrow[_txId].status = Status.Cancelled;
        nft.transferFrom(address(this), msg.sender, escrow[_txId].tokenId);
        emit CancleEscrow(
            _txId,
            escrow[_txId].tokenId,
            escrow[_txId].paymentAmount,
            escrow[_txId].tokenAddress
        );
    }

    function payEscrow(uint256 _txId) external payable onlyBuyer(_txId) {
        require(block.timestamp < escrow[_txId].deadline, "Deadline reached");
        require(
            escrow[_txId].status == Status.Pending,
            "Escrow is not in pending status"
        );
        IERC721 nft = IERC721(escrow[_txId].tokenAddress);
        uint256 amountAfterFee = _calculateFee(msg.value);
        escrow[_txId].status = Status.Accepted;
        (bool status, ) = payable(escrow[_txId].sellerAddress).call{value: amountAfterFee}("");
        require(status, "Transfer failed");
        nft.transferFrom(address(this), msg.sender, escrow[_txId].tokenId);
        emit PayEscrow(
            _txId,
            block.timestamp,
            escrow[_txId].tokenId,
            escrow[_txId].paymentAmount
        );
    }

    function rejectEscrow(uint256 _txId) external onlyBuyer(_txId) {
        require(block.timestamp < escrow[_txId].deadline, "Deadline reached");
        require(
            escrow[_txId].status == Status.Pending,
            "Escrow is not in pending status"
        );
        IERC721 nft = IERC721(escrow[_txId].tokenAddress);
        escrow[_txId].status = Status.Rejected;
        nft.transferFrom(address(this), msg.sender, escrow[_txId].tokenId);
    }
    
    function _calculateFee(uint256 _paymentAmount) private view returns(uint256 amountAfterFee) {
        uint256 feeAmount = _paymentAmount.mul(fee).div(100);
        amountAfterFee = _paymentAmount.sub(feeAmount);
    }
}
