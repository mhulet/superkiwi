class ShopifyService
  include Singleton

  def initialize
    @shopify_api = ShopifyAPI::
  end

  def get_customer(customer_id)
    ShopifyAPI::Customer.find(customer_id)
  end
end
