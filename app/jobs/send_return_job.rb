class SendReturnJob < ActiveJob::Base
  queue_as :mailers

  def perform(droper_code, products_ids, giving_date)
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    droper = Droper.find_by(code: droper_code)
    products = ShopifyAPI::Product.find(
      :all,
      params: { ids: products_ids.join(",") }
    ).sort { |a,b|
      a.variants.first.sku[/\d+/].to_i <=> b.variants.first.sku[/\d+/].to_i
    }
    max_droping_date = Date.parse(products.last.published_at)
    giving_date = Date.parse(giving_date)
    max_product_reference = products.last.variants.first.sku
    DroperMailer.returns(
      droper,
      products,
      max_droping_date,
      giving_date,
      max_product_reference
    ).deliver_now
  end
end
