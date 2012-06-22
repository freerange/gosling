require "java"

java_import java.lang.Runnable

require "main"
require "end-to-end/fake_auction_server"
require "end-to-end/auction_sniper_driver"

class ApplicationRunner
  SNIPER_ID = "sniper"
  SNIPER_PASSWORD = "sniper"

  def start_bidding_in(auction)
    thread = java.lang.Thread.new(
      Class.new do
        include Runnable
        def initialize(auction)
          @auction = auction
        end
        def run
          Main.main(FakeAuctionServer::XMPP_HOSTNAME, SNIPER_ID, SNIPER_PASSWORD, @auction.item_id)
        rescue => e
          p e
        end
      end.new(auction),
      "Test Application"
    )
    thread.setDaemon(true)
    thread.start
    @driver = AuctionSniperDriver.new(1000)
    @driver.shows_sniper_status(MainWindow::STATUS_JOINING)
  end

  def shows_sniper_has_lost_auction
    @driver.shows_sniper_status(MainWindow::STATUS_LOST)
  end

  def stop
    unless @driver.nil?
      @driver.dispose
    end
  end
end