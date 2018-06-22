class GenerateLabelsJob < ActiveJob::Base
  queue_as :default

  def perform(uploaded_file_path, uploaded_file_name)
    xls_file  = Roo::Spreadsheet.open(uploaded_file_path)
    products  = get_products_from_sheet(xls_file.sheet(0))
    pdf       = generate_pdf_from_string(products)
    file_name = File.basename(uploaded_file_name, ".*")
    ApplicationMailer.generated_labels(file_name, pdf).deliver_now
  end

  private

  def generate_pdf_from_string(products)
    av = ActionView::Base.new()
    av.view_paths = ActionController::Base.view_paths
    # need these to reference helper methods within PDF layout
    av.class_eval do
      include ApplicationHelper
    end
    WickedPdf.new.pdf_from_string(
      av.render(
        template: "labels/sheets",
        layout: "layouts/pdf/labels",
        locals: {
          :@products => products
        }
      ),
      orientation: "Landscape",
      lowquality: true
    )
  end

  def get_products_from_sheet(sheet)
    products = []
    sheet.each(
      sku: "Référence",
      size: "Taille",
      price: "Prix de vente",
      title: "Titre internet"
    ) do |row|
      break if row[:sku].nil?
      if row[:sku] && row[:sku] != "Référence" && row[:sku] != "Variant SKU"
        products << row
      end
    end
    products
  end
end
