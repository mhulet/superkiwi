module Embedded
  class AlertsController < Embedded::BaseController
    def index
      @alert = Alert.find_by(customer_id: @customer.id)
    end

    def new
      @alert = Alert.new
    end

    def create
      @alert = Alert.new(alert_params)
      @alert.customer_id = @customer.id
      if @alert.save
        redirect_to(
          embedded_alerts_path(passthrough_params),
          notice: "Super, votre alerte a été ajoutée. Vous recevrez dorénavant " +
            "un email au matin lorsque de nouveaux articles répondent à " +
            "vos critères."
        )
      else
        render :new
      end
    end

    def edit
      @alert = Alert.find_by(customer_id: @customer.id)
    end

    def update
      @alert = Alert.find(params[:id])
      if @alert.update_attributes(alert_params)
        redirect_to(
          embedded_alerts_path(passthrough_params),
          notice: "Votre alerte a été mise à jour 👍"
        )
      else
        render :edit
      end
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
