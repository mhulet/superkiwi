class BulkProductsController < ApplicationController
  def index; end

  def create
    ProcessBulkProductsJob.perform_now(params[:bulk_products_file].path)
    redirect_to bulk_products_path,
                notice: "Les articles vont être traités prochainement. Merci d'être vous."
  end
end
