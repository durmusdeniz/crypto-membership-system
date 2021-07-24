const {expectRevert, constants, time}  = require('@openzeppelin/test-helpers');
const MembershipSystem = artifacts.require('CryptoMemberships.sol');
const MembershipToken = artifacts.require('MembershipToken.sol');

const ONE_WEEK = time.duration.weeks(1);
const THIRTY_DAYS = time.duration.days(30);
const NINETY_DAYS = time.duration.days(90);

contract('MembershipSystem', addresses =>{
    const [admin, merchant, subscriber, _] = addresses;
    let membershipSystem, token;

    beforeEach(async() =>{
        membershipSystem = await MembershipSystem.new({from : merchant});
        token = await MembershipToken.new();

        await token.transfer(subscriber, 1000);
        await token.approve(membershipSystem.address, 1000, {from: subscriber});
    });

    it('creates plans', async() =>{

        await membershipSystem.createMembershipPlan(token.address, 25, ONE_WEEK, {from: merchant});
        await membershipSystem.createMembershipPlan(token.address, 100, THIRTY_DAYS, {from: merchant});
        await membershipSystem.createMembershipPlan(token.address, 300, NINETY_DAYS, {from: merchant});

        const weekly = await membershipSystem.membershipPlans(0);
        const monthly = await membershipSystem.membershipPlans(1);
        const quarterly = await membershipSystem.membershipPlans(2);

        assert(weekly.token === token.address);
        assert(weekly.amount.toString() === '25');
        assert(weekly.frequency.toString() === ONE_WEEK.toString());

        assert(monthly.token === token.address);
        assert(monthly.amount.toString() === '100');
        assert(monthly.frequency.toString() === THIRTY_DAYS.toString());

        assert(quarterly.token === token.address);
        assert(quarterly.amount.toString() === '300');
        assert(quarterly.frequency.toString() === NINETY_DAYS.toString());
    });


    it('fails to create a plan', async () => {
        await expectRevert(
            membershipSystem.createMembershipPlan(constants.ZERO_ADDRESS, 100, THIRTY_DAYS, {from: merchant}),
            'Token address null'
        );
        await expectRevert(
            membershipSystem.createMembershipPlan(token.address, 0, THIRTY_DAYS, {from: merchant}),
            'membership amount is 0'
        );
        await expectRevert(
            membershipSystem.createMembershipPlan(token.address, 100, 0, {from: merchant}),
            'membership frequency is 0'
        );
    });

    it('subscribe and make payment', async() =>{

        let merchantBalance, memberBalance;
        await membershipSystem.createMembershipPlan(token.address, 25, ONE_WEEK, {from: merchant});

        await membershipSystem.subscribe(0,{from: subscriber});

        merchantBalance = await token.balanceOf(merchant);
        memberBalance = await token.balanceOf(subscriber);

        assert(merchantBalance.toString() === '25');
        assert(memberBalance.toString() === '975' );

    });

    it('attempt to subscribe to a non existent plan', async() =>{
        await expectRevert(membershipSystem.subscribe(0,{from: subscriber}), 'no such membership plan');
    });
});