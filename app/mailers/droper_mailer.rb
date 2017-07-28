class DroperMailer < ActionMailer::Base
  default from: "Petit Kiwi <info@petitkiwi.be>"

  def monthly_report(droper, sales, revenues, year, month)
    @date         = Date.parse("#{year}-#{month}-01")
    @sales        = sales
    @revenues     = revenues
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

  def returns(droper, droping_date, products)
    @droper       = droper
    @droping_date = droping_date
    @products     = products
    mail(
      to: "coucou@petitkiwi.be",
      subject: "Petit Kiwi - Retour de vos articles invendus (mise en vente du #{l(@droping_date)})"
    )
  end
end
