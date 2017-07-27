class DroperMailer < ActionMailer::Base
  default from: "Petit Kiwi <info@petitkiwi.be>"

  def monthly_report(droper, sales, revenues, year, month)
    @date = Date.parse("#{year}-#{month}-01")
    @sales = sales
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
end
