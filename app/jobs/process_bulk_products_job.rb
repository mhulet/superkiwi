require "csv"

class ProcessBulkProductsJob < ActiveJob::Base
  queue_as :default

  def perform(bulk_products_file_path)
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    email_body = "<p>Résultat du traitement des articles:</p><ul>"

    # foreach product in the CSV
    CSV.foreach(bulk_products_file_path, headers: true) do |product_row|
      begin
        puts "Processing row..."
        product_sku   = product_row[0]
        product_title = product_row[1]
        process_type  = product_row[2]
        product_tags  = product_row[3]
        puts "  SKU: #{product_sku}"

        product = find_product(product_sku, product_title)
        if product.nil?
          puts "  ERROR: product not found!"
          email_body << "<li>#{product_sku}: #{process_type} → ERREUR!</li>"
        else
          process_product(product, process_type, product_tags)
          email_body << "<li>#{product_sku}: #{process_type} → OK!</li>"
        end
      rescue StandardError => e
        puts "ERROR! #{e.message}"
        email_body << "<li>#{product_sku}: #{process_type} → ERREUR! #{e.message}</li>"
      end

      sleep 0.25.seconds
    end

    email_body << "</ul>"

    ApplicationMailer.job_done(
      "Super Kiwi: résultat du traitement des articles",
      email_body
    ).deliver_now
  end

  def find_product(product_sku, product_title)
    products_with_title_count = ShopifyAPI::Product.count(
      title: product_title
    )
    nb_pages = (products_with_title_count / 250.0).ceil

    1.upto(nb_pages) do |page|
      products_with_title = ShopifyAPI::Product.find(
        :all,
        params: {
          title: product_title,
          limit: 250,
          page: page
        }
      )

      products_with_title.each do |product|
        product_variant = product.variants.first
        if product_variant.sku == product_sku
          return product
        else
          next
        end
      end

      sleep 0.25.seconds
    end
    return nil
  end

  def process_product(product, process_type, product_tags)
    case process_type
    when 'activer'
      puts "  Enabling product #{product.variants.first.sku}..."
      product.published_at = Time.now
    when 'désactiver'
      puts "  Disabling product #{product.variants.first.sku}..."
      product.published_at = nil
    else
      puts "  WARNING! Action unknown for #{product.variants.first.sku}: #{process_type}"
    end
    product.tags << ", #{product_tags}" if !product_tags.empty?
    product.save
  end
end
