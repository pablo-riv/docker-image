class PackingsController < ApplicationController
  before_action :set_packing, only: %i[show update edit destroy]
  
  def show; end

  def edit; end

  def new
    @packing = current_account.current_company.packings.new
  end

  def create
    packing = current_account.current_company.packings.new(packing_params)
    if packing.save!
      flash[:success] = I18n.t('settings.packings.messages.created')
      redirect_to packing_path(packing)
    else
      flash[:danger] = I18n.t('settings.packings.messages.create_unprocesable_entity')
      redirect_back(fallback_location: {action: :new})
    end
  rescue StandardError => e
    flash[:danger] = I18n.t('settings.packings.messages.created_error')
    redirect_back(fallback_location: {action: :new})
  end

  def update
    if @packing.update(packing_params)
      flash[:success] = I18n.t('settings.packings.messages.updated')
      redirect_to packing_path(@packing)
    else
      flash[:danger] = I18n.t('settings.packings.messages.update_unprocesable_entity')
      redirect_to edit_packing_path(@packing)
    end
  rescue StandardError => e
    flash[:danger] = I18n.t('settings.packings.messages.updated_error')
    redirect_to edit_packing_path(@packing)
  end

  def destroy
    if @packing.update(archive: true)
      flash[:success] = I18n.t('settings.packings.messages.destroyed')
      redirect_to settings_path
    else
      flash[:danger] = I18n.t('settings.packings.messages.destroy_unprocesable_entity')
      redirect_to settings_path
    end
  rescue StandardError => e
    flash[:danger] = I18n.t('settings.packings.messages.destroyed_error')
    redirect_to settings_path
  end

  private

  def set_packing
    @packing = Packing.find_by(id: params[:id] || params[:packing_id])
  end

  def packing_params
    params.require(:packing).permit(Packing.allowed_attributes)
  end
end
