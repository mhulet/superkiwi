module Embedded
  class AlertsController < Embedded::BaseController
    def index
      @alerts = Alert.all
    end

    def new
      @alert = Alert.new
    end

    def create
      @alert = Alert.new(alert_params)
      if @alert.save
        redirect_to embedded_alerts_path, notice: "L'alerte a été ajoutée."
      else
        render :new
      end
    end

    def edit

    end

    def update

    end

    def destroy

    end

    private

    def alert_params
      params.require(:alert).permit(
        :customer_id,
        categories_ids: []
      )
    end
  end
end
