namespace :products do
  task csv_lines: :environment do
    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    products_count = ShopifyAPI::Product.count
    nb_pages = (products_count / 250.0).ceil

    start_time = Time.now
    1.upto(nb_pages) do |page|
      unless page == 1
        stop_time = Time.now
        processing_duration = stop_time - start_time
        wait_time = (CYCLE - processing_duration).ceil
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
        product_to_csv_line(product)
      end
    end
  end

  task dropings: :environment do
    CYCLE = 0.5.seconds

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
        wait_time = (CYCLE - processing_duration).ceil
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
        dropings[droper_code][Date.parse(product.created_at).to_s] ||= 0
        dropings[droper_code][Date.parse(product.created_at).to_s] += 1
      end
    end

    # puts "Date du jour: #{Date.today}"
    # puts "------------"
    dropings.each do |droper_code, droper_dates|
      # puts "#{droper_code}:"
      droper_dates.each do |droper_date, products_count|
        # puts "  #{droper_date}: #{products_count} articles en vente"
        puts "#{droper_code};#{droper_date};#{products_count}"
      end
      # puts ""
    end
  end

  def product_to_csv_line(product)
    variant = product.variants.first
    return if variant.inventory_quantity < 1 || product.published_at.nil?
    puts "#{product.created_at};#{variant.sku};#{product.title};#{product.vendor};#{variant.price};#{variant.inventory_quantity};#{product.tags};#{product.images.first.src rescue ''}"
  end
end
