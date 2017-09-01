class DroperMailer < ActionMailer::Base
  helper :application
  default from: "Petit Kiwi <info@petitkiwi.be>"

  def monthly_report(droper, sales, revenues, year, month)
    @date     = Date.parse("#{year}-#{month}-01")
    @sales    = sales
    @revenues = revenues
    mail(
        to: droper.email,
        subject: "Petit Kiwi - vos ventes #{l(@date, format: :month_year)}"
      )
  end

  def late_payments(droper)
    mail(
      to: droper.email,
      subject: "Petit Kiwi - retard dans le paiement de vos ventes de juillet"
    )
  end

  def returns(droper, products, max_droping_date, giving_date, max_product_reference)
    @droper                = droper
    @products              = products
    @max_droping_date      = max_droping_date
    @giving_date           = giving_date
    @max_product_reference = max_product_reference
    mail(
      to: "info@petitkiwi.be",
      subject: "Bientôt 1 an que vos articles sont en vente. Souhaitez-vous récupérer les invendus? (réf: #{@droper.code})"
    )
  end
end
