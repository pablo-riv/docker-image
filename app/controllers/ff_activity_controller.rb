class FfActivityController < ApplicationController
  before_action :set_activity, only: [:show]

  def show
    @activity_created_at = Time.parse(@activity['created_at'])
  end

  private

  def set_activity
    @activity = FulfillmentService.inventory(params[:id])
  end
end
