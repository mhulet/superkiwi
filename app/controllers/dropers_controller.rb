class DropersController < ApplicationController
  def index
    @dropers = Droper.all
  end

  def show
    @droper = Droper.find(params[:id])
  end

  def new
    @droper = Droper.new
  end

  def edit
    @droper = Droper.find(params[:id])
    @previous_droper = Droper.find(params[:id].to_i - 1) rescue nil
    @next_droper = Droper.find(params[:id].to_i + 1) rescue nil
  end

  def create
    @droper = Droper.new(params[:droper])

    if @droper.save
      redirect_to @droper, notice: "Droper was successfully created."
    else
      render action: "new"
    end
  end

  def update
    @droper = Droper.find(params[:id])

    if @droper.update_attributes(params[:droper])
      redirect_to edit_droper_path(@droper),
                  notice: "Les informations concernant ce déposant ont été mises à jour."
    else
      render action: "edit"
    end
  end

  def send_report
    @from_date = DateTime.parse("#{params[:y]}-#{params[:m]}-01")
    @to_date = @from_date.at_end_of_month
    seconds_counter = 20
    Droper.all.each do |droper|
      droper.send_report(@from_date, @to_date, seconds_counter)
      seconds_counter += 20
    end
  end
end
