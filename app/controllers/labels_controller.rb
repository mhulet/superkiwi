class LabelsController < ApplicationController
  def new; end

  def create
    ephemeral_file = params[:file]
    ephemeral_file_name = File.basename(ephemeral_file.path)
    tmp_file_path = Rails.root.join("tmp/#{ephemeral_file_name}")
    FileUtils.mv(ephemeral_file.path, tmp_file_path)
    GenerateLabelsJob.perform_later(
      tmp_file_path.to_s,
      ephemeral_file.original_filename
    )
    redirect_to(
      new_label_path,
      notice: "Merci, je m'en occupe. Je vous envoie les étiquettes par email dès qu'elles sont prêtes."
    )
  end
end
