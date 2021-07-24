pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract CryptoMemberships {
    uint public nextMembershipPlanId;
    address merchant;

    struct MembershipPlan{ address merchantAddress; address token; uint amount; uint frequency; }
    struct Membership{ address member; uint start; uint nextCharge; }

    mapping(uint => MembershipPlan) public membershipPlans;
    mapping(address => mapping(uint => Membership)) public memberships;


    event MembershipPlanCreated(address merchant, uint membershipPlanId, uint creationDate);
    event MembershipCreated(address member, uint membershipPlanId, uint subscriptionDate);
    event MembershipCancelled(address member, uint membershipPlanId, uint cancellationDate);
    event MembershipRefunded(address member, uint membershipPlanId, uint refundDate, bool fullAmount);
    event MembershipPaid( address fromAddress, address toAddress, uint payAmount, uint membershipPlanId, uint payDate);



    constructor() { merchant = msg.sender;}

    function createMembershipPlan(address token, uint amount, uint renewalFrequency) external {
        require(msg.sender == merchant, 'Creator not merchant' );
        require(token != address(0), 'Token address null');
        require(amount > 0, 'membership amount is 0');
        require(renewalFrequency > 0, 'membership frequency is 0');
        membershipPlans[nextMembershipPlanId] = MembershipPlan(merchant, token, amount, renewalFrequency);
        nextMembershipPlanId++;
    }

    function subscribe(uint membershipPlanId) external {
        IERC20 token = IERC20(membershipPlans[membershipPlanId].token);
        MembershipPlan storage membershipPlan = membershipPlans[membershipPlanId];

        require(membershipPlan.merchantAddress != address(0), 'no such membership plan');
        token.transferFrom(msg.sender, membershipPlan.merchantAddress, membershipPlan.amount);

        memberships[msg.sender][membershipPlanId] = Membership( msg.sender, block.timestamp, block.timestamp + membershipPlan.frequency);


        emit MembershipPaid(msg.sender, membershipPlan.merchantAddress, membershipPlan.amount, membershipPlanId, block.timestamp);
        emit MembershipCreated(msg.sender, membershipPlanId, block.timestamp);

    }

    function cancel(uint membershipPlanId) external {
        Membership storage membership = memberships[msg.sender][membershipPlanId];
        require(membership.member != address(0), 'no such membership');
        delete memberships[msg.sender][membershipPlanId];

        emit MembershipCancelled(msg.sender, membershipPlanId, block.timestamp);

    }

    function renew(address member, uint membershipPlanId) external {
        Membership storage membership = memberships[member][membershipPlanId];
        MembershipPlan storage membershipPlan = membershipPlans[membershipPlanId];
        IERC20 token = IERC20(membershipPlan.token);

        require(membership.member != address(0), 'no such membership');
        require(block.timestamp > membership.nextCharge,'membership renewal not due');

        token.transferFrom(member, membershipPlan.merchantAddress, membershipPlan.amount);

        emit MembershipPaid(member, membershipPlan.merchantAddress, membershipPlan.amount, membershipPlanId, block.timestamp);

        membership.nextCharge = membership.nextCharge + membershipPlan.frequency;
    }

    function refund(address member, uint membershipPlanId, uint refundAmount) external {
        Membership storage membership = memberships[member][membershipPlanId];
        MembershipPlan storage membershipPlan = membershipPlans[membershipPlanId];
        IERC20 token = IERC20(membershipPlan.token);

        require(membership.member != address(0), 'no such membership');
        require(membershipPlan.amount >= refundAmount,'refund amount must be less or equal to paid amount');
        require(msg.sender == merchant, 'only merchant can refund');

        token.transferFrom(membershipPlan.merchantAddress, member, refundAmount);

        delete memberships[member][membershipPlanId];

        emit MembershipRefunded(member, membershipPlanId, block.timestamp, membershipPlan.amount == refundAmount);

    }
}