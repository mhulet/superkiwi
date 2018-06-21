class LabelsController < ApplicationController
  def new
    # show form with file input
    droping_xls_file = Roo::Spreadsheet.open("./depot.xls")
    products_sheet = droping_xls_file.sheet(0)
    @products = []
    products_sheet.each(sku: "Référence", size: "Taille", price: "Prix de vente", title: "Titre internet") do |row|
      if row[:sku] && row[:sku] != "Référence" && row[:sku] != "Variant SKU"
        @products << row
      end
      if row[:sku].nil?
        break
      end
    end
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Etiquettes",
               layout: "labels",
               show_as_html: params.key?('debug'),
               orientation: 'Landscape',
               grayscale: true,
               lowquality: true,
               margin:  {   top:               10,
                            bottom:            10,
                            left:              10,
                            right:             10 }
      end
    end
  end

  def create
    # open file
    # load lines
    # perform job to generate pdf
    # email pdf to info@petitkiwi.be

  end
end
