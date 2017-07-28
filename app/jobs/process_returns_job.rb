class ProcessReturnsJob < ActiveJob::Base
  queue_as :default

  def perform(max_date)
    cycle = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    products_count = ShopifyAPI::Product.count
    nb_pages = (products_count / 250.0).ceil

    dropings = Hash.new

    start_time = Time.now
    1.upto(nb_pages) do |page|
      unless page == 1
        stop_time = Time.now
        processing_duration = stop_time - start_time
        wait_time = (cycle - processing_duration).ceil
        sleep wait_time if wait_time > 0
        start_time = Time.now
      end
      products = ShopifyAPI::Product.find(
        :all,
        params: {
          limit: 250,
          page: page
        }
      )
      products.each do |product|
        variant = product.variants.first
        next if variant.inventory_quantity < 1 || product.published_at.nil? || variant.sku.nil?
        droper_code = variant.sku.gsub(/[^a-zA-Z]/, "")
        dropings[droper_code] ||= Hash.new
        dropings[droper_code][Date.parse(product.created_at).to_s] ||= Array.new
        dropings[droper_code][Date.parse(product.created_at).to_s].push(product.id)
      end
    end

    run_in_seconds = 0
    dropings.each do |droper_code, droping_dates|
      droping_dates.each do |droping_date, products_ids|
        SendReturnJob
          .set(wait: run_in_seconds.seconds)
          .perform_later(droper_code, droping_date, products_ids)
        run_in_seconds += 10
      end
    end
  end
end
