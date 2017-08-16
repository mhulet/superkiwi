require "csv"

class ProcessReturnsJob < ActiveJob::Base
  queue_as :default

  def perform(max_droping_date, giving_date)
    cycle = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    products_count = ShopifyAPI::Product.count
    nb_pages = (products_count / 250.0).ceil

    sold_products = {}

    sold_products_csv = CSV.generate { |csv| csv = %w{sku title published_at taille} }


    sold_products_csv = CSV.generate do |csv|
      csv << %w{sku title published_at taille}

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
            page: page,
            published_at_max: DateTime.parse(max_droping_date).iso8601
          }
        )
        products.each do |product|
          variant = product.variants.first
          next if variant.inventory_quantity < 1 || product.published_at.nil? || variant.sku.nil?
          next if product.published_at >= max_droping_date
          droper_code = variant.sku.gsub(/[^a-zA-Z]/, "")
          # sold_products[droper_code] ||= []
          # sold_products[droper_code].push(product.id)
          csv << product_as_csv_row(product, variant)
        end
      end
    end

    ApplicationMailer.returns_csv(
      max_droping_date,
      giving_date,
      sold_products_csv
    ).deliver_now

    # run_in_seconds = 0
    # sold_products.each do |droper_code, products_ids|
    #   SendReturnJob
    #     .set(wait: run_in_seconds.seconds)
    #     .perform_later(droper_code, products_ids, giving_date)
    #   run_in_seconds += 10
    # end
  end

  def product_as_csv_row(product, variant)
    [
      variant.sku,
      variant.title,
      product.published_at,
      ApplicationController.helpers.product_size(product)
    ]
  end
end
