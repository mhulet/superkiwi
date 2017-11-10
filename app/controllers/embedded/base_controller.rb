module Embedded
  class BaseController < ApplicationController
    skip_before_action :authenticate
    before_action :authorize_and_set_customer
    before_action :allow_iframes

    layout 'embedded'

    private

    def allow_iframes
      response.headers['X-FRAME-OPTIONS'] =
        'ALLOW-FROM https://www.petitkiwi.be'
    end

    def authorize_and_set_customer
      # /embedded/alerts?customer_id=4341589446&customer_email=info@petitkiwi.be
      @customer = ShopifyAPI::Customer.find(params[:customer_id])
      if @customer.email != params[:customer_email]
        # TODO: redirect to error page
        redirect_to :root_path
      end
    rescue
      # TODO: redirect to error page
      # currently it renders a 404 error (returned by Shopify)
    end

    def passthrough_params
      {}.tap { |passthrough|
        passthrough[:customer_id]     = @customer.id
        passthrough[:customer_email]  = @customer.email
      }
    end
    helper_method :passthrough_params
  end
end
