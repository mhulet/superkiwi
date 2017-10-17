module Embedded
  class AlertsController < Embedded::BaseController
    def index
      @alerts = Alert.where(customer_id: @customer.id)
    end

    def new
      @alert = Alert.new
    end

    def create
      @alert = Alert.new(alert_params)
      @alert.customer_id = @customer.id
      if @alert.save
        redirect_to embedded_alerts_path, notice: "Votre alerte a été ajoutée. Vous recevrez dorénavant un email au matin lorsque de nouveaux articles correspondent à vos critères."
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
        categories_ids: []
      )
    end
  end
end
