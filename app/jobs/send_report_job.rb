class SendReportJob < ActiveJob::Base
  queue_as :mailers

  def perform(droper_id, report_sales_dup, report_revenues, from_date, to_date)
    droper = Droper.find(droper_id)
    DroperMailer.monthly_report(
      droper,
      report_sales_dup,
      report_revenues,
      Date.parse(from_date),
      Date.parse(to_date)
    ).deliver_now
    droper.update_column(:report_sent_at, Time.now)
  end
end
