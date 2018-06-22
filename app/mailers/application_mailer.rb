class ApplicationMailer < ActionMailer::Base
  default from: "info@petitkiwi.be"

  def generated_labels(original_filename, pdf)
    @original_filename = original_filename
    attachments["Étiquettes - #{original_filename}.pdf"] = pdf
    mail(
      to: "michael@hulet.eu",
      subject: "🏷 Étiquettes - #{original_filename}",
    )
  end

  def job_done(subject, body)
    @email_body = body
    mail(
      to: "info@petitkiwi.be",
      subject: subject
    )
  end

  def returns_csv(max_droping_date, giving_date, sold_products_csv)
    @max_droping_date      = max_droping_date
    @giving_date           = giving_date
    attachments["retours.csv"] = {
      mime_type: "text/csv",
      content: sold_products_csv
    }
    mail(
      to: "info@petitkiwi.be",
      subject: "Super Kiwi: CSV des articles concernés par les retours"
    )
  end

  def sales_imported(import_count, lines_count, import_errors)
    @import_count = import_count
    @lines_count = lines_count
    @import_errors = import_errors
    mail(
      to: "info@petitkiwi.be",
      subject: "Super Kiwi: import des ventes terminé"
    )
  end
end
