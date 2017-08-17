require "csv"

class ProcessBulkProductsJob < ActiveJob::Base
  queue_as :default

  def perform(bulk_products_file_path)
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    # foreach product in the CSV
    CSV.foreach(bulk_products_file_path, headers: true) do |product_row|
      product_sku   = product_row[0]
      product_title = product_row[1]
      process_type  = product_row[2]
      product_tags  = product_row[3]

      products_with_title = ShopifyAPI::Product.find(
        :all,
        params: {
          title: product_title
        }
      )

      products_with_title.each do |product|
        product_variant = product.variants.first
        if product_variant.sku == product_sku
          process_product(product, process_type, product_tags)
          break
        end
      end

      sleep 0.5.seconds
    end
  end

  def process_product(product, process_type, product_tags)
    case process_type
    when 'activer'
      puts "enabling product #{product.variants.first.sku}..."
      product.published_at = Time.now
    when 'désactiver'
      puts "disabling product #{product.variants.first.sku}..."
      product.published_at = nil
    end
    product.tags << ", #{product_tags}" if !product_tags.empty?
    product.save
  end
end
