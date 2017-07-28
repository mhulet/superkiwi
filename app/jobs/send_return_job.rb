class SendReturnJob < ActiveJob::Base
  queue_as :mailers

  def perform(droper_code, droping_date, products_ids)
    shop_url = "https://#{ENV['SHOPIFY_API_KEY']}:#{ENV['SHOPIFY_PASSWORD']}@#{ENV['SHOPIFY_SHOP_NAME']}.myshopify.com/admin"
    ShopifyAPI::Base.site = shop_url
    droper = Droper.find_by(code: droper_code)
    droping_date = Date.parse(droping_date)
    products = ShopifyAPI::Product.find(:all, params: { ids: products_ids.join(",") })
    DroperMailer.returns(
      droper,
      droping_date,
      products
    ).deliver_now
  end
end
