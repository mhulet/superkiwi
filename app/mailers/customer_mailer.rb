class CustomerMailer < ActionMailer::Base
  default from: "Petit Kiwi <info@petitkiwi.be>"

  def alert(customer_id, collections)
    @customer     = ShopifyAPI::Customer.find(customer_id)
    @collections  = collections
    mail(
      to: @customer.email,
      subject: 'Petit Kiwi - nouveaux articles répondant à vos critères'
    )
  end
end
