class SkusController < ApplicationController
  before_action :set_company, only: %i[show by_client]
  before_action :set_sku, only: %i[show]
  before_action :set_notification, only: %i[show by_client]

  def show; end

  def by_client
    client_skus = FulfillmentService.by_client(@company.id)
    render json: { state: :ok, client_skus: client_skus }, status: :ok
  rescue
    render json: 'error al obtener los skus', status: :error
  end

  def update_min_stock
    params[:skus].each do |sku|
      FulfillmentService.update_min_stock(sku)
    end
    render json: { state: :ok }, status: :ok
  rescue => e
    Rails.logger.info { e.message }
    render json: 'error al obtener los skus', status: :error
  end

  private

  def set_sku
    @sku = FulfillmentService.sku(params[:id])
  end

  def set_company
    @company = current_account.current_company
  end

  def set_notification
    @notifications = @company.settings.find_by(service_id: 6)
  end
end
