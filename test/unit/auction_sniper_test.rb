require "test_helper"

require "auction_sniper"
require "price_source"
require "sniper_snapshot"

describe AuctionSniper do
  ITEM_ID = "item-id"

  before do
    @auction = mock("Auction")
    @sniper_listener = mock("SniperListener")
    @sniper = AuctionSniper.new(ITEM_ID, @auction, @sniper_listener)
    @sniper_state = states("sniper")
  end

  it "reports lost when auction closes immediately" do
    @sniper_listener.expects(:sniper_lost).at_least_once
    @sniper.auction_closed
  end

  it "reports lost if auction closes when bidding" do
    @auction.stub_everything
    @sniper_listener.stubs(:sniper_bidding).with(instance_of(SniperSnapshot)).then(@sniper_state.is("bidding"))
    @sniper_listener.expects(:sniper_lost).at_least_once.when(@sniper_state.is("bidding"))

    @sniper.current_price(123, 45, PriceSource::FROM_OTHER_BIDDER)
    @sniper.auction_closed
  end

  it "reports won if auction closes when winning" do
    @auction.stub_everything
    @sniper_listener.stubs(:sniper_winning).then(@sniper_state.is("winning"))
    @sniper_listener.expects(:sniper_won).at_least_once.when(@sniper_state.is("winning"))

    @sniper.current_price(123, 45, PriceSource::FROM_SNIPER)
    @sniper.auction_closed
  end

  it "bids higher and reports bidding when new price arrives" do
    price = 1001
    increment = 25
    bid = price + increment
    @auction.expects(:bid).with(bid)
    @sniper_listener.expects(:sniper_bidding).with(SniperSnapshot.new(ITEM_ID, price, bid)).at_least_once
    @sniper.current_price(price, increment, PriceSource::FROM_OTHER_BIDDER)
  end

  it "reports is winning when current price comes from sniper" do
    @sniper_listener.expects(:sniper_winning).at_least_once
    @sniper.current_price(123, 45, PriceSource::FROM_SNIPER)
  end
end
