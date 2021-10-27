class FulfillmentController < ApplicationController
  before_action :set_company, only: %i[history]
  before_action :set_activities, only: %i[history]
  before_action :set_skus, only: %i[history]

  def inventory; end

  def receipt; end

  def out; end

  def history
    render json: { company: @company, activities: @activities, skus: @skus, state: :ok }, status: :ok
  rescue => e
    puts e.message.to_s.red
    render json: { message: 'La operación ha fallado, favor contactar con desarrollo' }, status: :bad_request
  end

  private

  def set_company
    @company = current_account.entity_specific
  end

  def set_skus
    @skus = FulfillmentService.by_client(@company.id)
  end

  def set_activities
    @activities = FulfillmentService.inventory_activities_by(@company.id, JSON.parse(params[:inventory_activity_type_ids]), params[:page]) if @company.present?
  end
end
