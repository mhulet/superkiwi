namespace :products do
  task tags: :environment do
    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    products_count = ShopifyAPI::Product.count
    nb_pages = (products_count / 250.0).ceil

    shop_tags = {}

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
      puts "processing page #{page} of #{nb_pages}..."
      products.each do |product|
        product_tags = product.tags.split(',').collect(&:strip)
        product_tags.each do |tag|
          shop_tags[tag] ||= { active: [], sold: [] }
          variant = product.variants.first
          if variant.inventory_quantity < 1
            shop_tags[tag][:sold] << product.id
          else
            shop_tags[tag][:active] << product.id
          end
        end
      end
    end

    puts "tag;active_products_count;sold_products_count"
    shop_tags.each do |tag, products_ids_hashes|
      puts "#{tag};#{products_ids_hashes[:active].count};#{products_ids_hashes[:sold].count}"
    end
  end

  task remove_tags_on_sold_products: :environment do
    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    products_count = ShopifyAPI::Product.count(
      updated_at_max: Date.today - 3.months
    )
    nb_pages = (products_count / 250.0).ceil
    puts "Products updated more than 3 months ago: #{products_count}"

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
          page: page,
          updated_at_max: Date.today - 3.months
        }
      )
      products.each do |product|
        begin
          if product.variants.first.inventory_quantity == 0
            tags = product.tags.split(',').collect(&:strip)
            new_tags = []
            tags.each do |tag|
              droper = Droper.find_by(code: tag)
              if !droper.nil?
                new_tags << tag
              end
            end
            puts "#{product.title} (#{product.variants.first.sku})"
            puts "  inventory    : #{product.variants.first.inventory_quantity}"
            puts "  current tags : #{product.tags}"
            puts "  new tags     : #{new_tags.join(', ')}"
            product.tags = new_tags.join(', ')
            product.save
          end
        end
      end
    end
  end

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
