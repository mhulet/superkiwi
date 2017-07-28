class ReturnsController < ApplicationController
  def new
    @return = Return.new
  end

  def create
    @return = Return.new(
      max_date: "#{return_params["max_date(1i)"]}-#{return_params["max_date(2i)"]}-#{return_params["max_date(3i)"]}",
      giving_date: "#{return_params["giving_date(1i)"]}-#{return_params["giving_date(2i)"]}-#{return_params["giving_date(3i)"]}"
    )
    ProcessReturnsJob.perform_later(@return.max_date, @return.giving_date)
    redirect_to new_return_path,
                notice: "Vous recevrez prochainement les emails destinés aux déposants pour vérification."
  end

  private

  def return_params
    params.require(:return).permit(
      "max_date(1i)", "max_date(2i)", "max_date(3i)",
      "giving_date(1i)", "giving_date(2i)", "giving_date(3i)",
    )
  end
end
