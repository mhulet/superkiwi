class LabelsController < ApplicationController
  def new; end

  def create
    file = params[:file]
    GenerateLabelsJob.perform_later(
      file.path,
      file.original_filename
    )
    redirect_to(
      new_label_path,
      notice: "Merci, je m'en occupe. Je vous envoie les étiquettes par email dès qu'elles sont prêtes."
    )
  end
end
