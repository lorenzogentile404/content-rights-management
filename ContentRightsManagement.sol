// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Content Rights Management
 * @dev This contract manages the digital rights and registrations of content creators and buyers.
 */
contract ContentRightsManagement {
    uint256 public registrationFee;
    address payable private owner; // Making sure owner is payable
    mapping(address => bool) public isContentCreator;
    mapping(address => bool) public isBuyer;
    mapping(bytes32 => Content) public contents;
    mapping(bytes32 => mapping(address => bool)) public contentRightsOwnership;

    struct Content {
        address payable creator; // Ensuring creator can receive payments
        uint256 price;
    }

    event ContentAdded(bytes32 hash, address indexed creator, uint256 price);
    event ContentPurchased(bytes32 hash, address indexed buyer, address indexed creator, uint256 price);
    event Withdrawal(uint256 amount, address indexed to);

    // Constructor to set the initial registration fee and owner
    constructor(uint256 _registrationFee) {
        registrationFee = _registrationFee;
        owner = payable(msg.sender); // Casting the owner as payable
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function registerContentCreator() external payable {
        require(msg.value == registrationFee, "Incorrect fee");
        require(!isContentCreator[msg.sender], "Already registered");
        isContentCreator[msg.sender] = true;
    }

    function registerBuyer() external payable {
        require(msg.value == registrationFee, "Incorrect fee");
        require(!isBuyer[msg.sender], "Already registered as buyer");
        isBuyer[msg.sender] = true;
    }

    function addContent(bytes32 hash, uint256 price) external payable {
        require(isContentCreator[msg.sender], "Not a registered creator");
        uint256 addingContentFee = price / 100;  // 1% of the content price
        require(msg.value == addingContentFee, "Incorrect content adding fee");
        require(contents[hash].creator == address(0), "Content already registered");

        contents[hash] = Content({
            creator: payable(msg.sender),  // Casting the sender as payable
            price: price
        });
        emit ContentAdded(hash, msg.sender, price);
    }

    function buyContent(bytes32 hash) external payable {
        require(isBuyer[msg.sender], "Not a registered buyer");
        Content storage content = contents[hash];
        require(content.creator != address(0), "Content does not exist");
        
        uint256 contentFee = content.price / 100;  // Calculate 1% fee
        uint256 totalPrice = content.price + contentFee;  // Total price includes the content price plus 1% fee
        require(msg.value == totalPrice, "Incorrect amount paid");

        // Transfer the content price to the creator
        content.creator.transfer(content.price);

        // Record the buyer as having the rights to the content
        contentRightsOwnership[hash][msg.sender] = true;

        emit ContentPurchased(hash, msg.sender, content.creator, content.price);
    }

    function verifyContentOwnership(bytes32 contentHash, address buyer) public view returns (bool) {
        return contentRightsOwnership[contentHash][buyer];
    }

    function withdrawFees() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No fees to withdraw");

        owner.transfer(amount);  // Using .transfer() for simplicity and safety
        emit Withdrawal(amount, owner);
    }
}
