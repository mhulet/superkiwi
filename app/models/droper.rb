class Droper < ActiveRecord::Base
  has_many :sales

  def name
    if self.lastname.present?
      "#{self.lastname.upcase} #{self.firstname rescue ''}"
    else
      self.code
    end
  end

  def status
    return false if !self.code
    return false if !self.email
    return false if !self.bank_account and self.commissionnable?
    return true # otherwise
  end

  def period_sales(from_date, to_date)
    self.sales.where("sold_at >= ? AND sold_at <= ?", from_date, to_date)
  end

  def send_report(from_date, to_date, run_in_seconds)
    report_sales = self.period_sales(from_date, to_date)
    report_sales_dup = Array.new
    if report_sales.present?
      report_sales_total = 0.0
      report_sales_commission = 0.0
      report_sales.each do |sale|
        report_sales_dup << sale
        report_sales_total += sale.amount
        if sale.amount < 10000
          report_sales_commission += sale.amount.to_f * 0.5
        else
          report_sales_commission += sale.amount.to_f * 0.4
        end
      end
      report_revenues = report_sales_total - report_sales_commission
    end
    if report_sales_dup.any?
      SendReportJob.set(wait: run_in_seconds.seconds).perform_later(self.id, report_sales_dup, report_revenues, from_date.to_s, to_date.to_s)
    end
  end
end
