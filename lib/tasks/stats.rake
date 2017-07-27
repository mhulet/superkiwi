namespace :stats do
  task average_cart_value_for_shipped_orders: :environment do
    CYCLE = 0.5.seconds

    puts "Connecting to Shopify store..."
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    orders_count = ShopifyAPI::Order.count(status: "any")
    nb_pages = (orders_count / 250.0).ceil

    puts "Count orders: #{orders_count}"

    start_time = Time.now

    orders_total = 0.0
    orders_count_for_average = 0
    1.upto(nb_pages) do |page|
      unless page == 1
        stop_time = Time.now
        puts "Last batch processing started at #{start_time.strftime('%I:%M%p')}"
        puts "The time is now #{stop_time.strftime('%I:%M%p')}"
        processing_duration = stop_time - start_time
        puts "The processing lasted #{processing_duration.to_i} seconds."
        wait_time = (CYCLE - processing_duration).ceil
        puts "We have to wait #{wait_time} seconds then we will resume."
        sleep wait_time if wait_time > 0
        start_time = Time.now
      end
      puts "Processing page #{page}/#{nb_pages}..."
      orders = ShopifyAPI::Order.find(:all, params: { status: "any", limit: 250, page: page })
      orders.each do |shopify_order|
        next if shopify_order.shipping_lines.count == 0 || shopify_order.shipping_lines.first.price.to_i == 0
        orders_total += shopify_order.subtotal_price.to_f
        orders_count_for_average += 1
        ap "Order #{shopify_order.id}: #{shopify_order.subtotal_price} EUR"
      end
    end
    ap "Average cart value = #{orders_total / orders_count_for_average}"
    puts "Over and out."
  end
end
