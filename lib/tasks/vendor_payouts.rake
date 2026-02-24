namespace :vendor_payouts do
  desc "Backfill vendor fee calculations for existing delivered orders"
  task backfill_fees: :environment do
    puts "Backfilling vendor fees for delivered orders..."

    orders = Order.where(status: "delivered", payment_status: "paid", vendor_earnings: 0)
    config = PlatformFeeConfig.current

    puts "Found #{orders.count} orders to process"

    orders.find_each do |order|
      begin
        fees = config.calculate_fees(order.total_amount)
        order.update!(
          platform_fee_amount: fees[:platform_fee],
          gateway_fee_amount: fees[:gateway_fee],
          gateway_gst_amount: fees[:gateway_gst],
          vendor_earnings: fees[:vendor_earnings]
        )
        print "."
      rescue => e
        puts "\nError processing order #{order.id}: #{e.message}"
      end
    end

    puts "\nDone! Processed #{orders.count} orders."
  end

  desc "Create initial platform fee config"
  task setup_config: :environment do
    if PlatformFeeConfig.count == 0
      PlatformFeeConfig.create!(
        platform_commission_percent: 10.0,
        gateway_fee_percent: 2.0,
        gateway_gst_percent: 18.0,
        minimum_payout_amount: 500.0,
        maximum_payout_amount: 50000.0,
        absorb_fees: true
      )
      puts "Platform fee configuration created successfully!"
    else
      puts "Platform fee configuration already exists."
    end
  end
end
