# encoding: utf-8
require "csv"
namespace :maintenance do
  desc "Post missing images for products with multiple images"
  task post_missing_images: :environment do
    CYCLE = 0.5.seconds

    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url

    prestashop_images_csv_path = "lib/assets/prestashop_images.csv"
    prestashop_images_csv_table = CSV.table(
      prestashop_images_csv_path,
      converters: :all
    )

    handles_csv_path = "lib/assets/products_with_missing_images.csv"
    CSV.foreach(handles_csv_path, headers: true) do |row|
      products_with_handle = ShopifyAPI::Product.find(
        :all,
        params: {
                  handle: row['handle']
                }
      )
      if products_with_handle.count == 1
        puts "Processing product: #{row['handle']}"
        product = products_with_handle.first
        puts "  product = #{product.inspect}"
        product_sku = product.variants.first.sku
        prestashop_images_csv_rows = prestashop_images_csv_table.select do |row|
          row.field(:reference) == product_sku
        end
        prestashop_images_csv_rows.each do |prestashop_image_csv_row|
          image = ShopifyAPI::Image.new(
            src: prestashop_image_csv_row.field(:image_url)
          )
          product.images << image
        end
        product.save
        puts "  #{prestashop_images_csv_rows.count} new image(s) for this product"
      end
      sleep CYCLE
    end
  end
end
