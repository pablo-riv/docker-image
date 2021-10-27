class ProductsController < ApplicationController
  before_action :set_product, only: %i[show update edit destroy]

  def index; end
  
  def show; end

  def edit; end

  def new
    @product = current_account.current_company.products.new
  end

  def create
    product = current_account.current_company.products.new(product_params)
    unless params[:product][:image].blank?
      image = product.upload_image(params[:product][:image])
      product.assign_attributes(image: image)
    end
    if product.save!
      flash[:success] = I18n.t('settings.products.messages.created')
      redirect_to product_path(product)
    else
      flash[:danger] = I18n.t('settings.products.messages.create_unprocesable_entity')
      redirect_back(fallback_location: {action: :new})
    end
  rescue StandardError => e
    flash[:danger] = "#{I18n.t('settings.products.messages.created_error')}: #{e.message}"
    redirect_back(fallback_location: {action: :new})
  end

  def update
    unless params[:product][:image].blank?
      image = @product.upload_image(params[:product][:image])
      @product.assign_attributes(image: image)
    end
    if @product.update(product_params)
      flash[:success] = I18n.t('settings.products.messages.updated')
      redirect_to product_path(@product)
    else
      flash[:danger] = I18n.t('settings.products.messages.update_unprocesable_entity')
      redirect_to edit_product_path(@product)
    end
  rescue StandardError => e
    puts e.backtrace.first(3).join("\n").red.swap
    flash[:danger] = I18n.t('settings.products.messages.updated_error')
    redirect_to edit_product_path(@product)
  end

  def destroy
    if @product.update(archive: true)
      flash[:success] = I18n.t('settings.products.messages.destroyed')
      redirect_to settings_path
    else
      flash[:danger] = I18n.t('settings.products.messages.destroy_unprocesable_entity')
      redirect_to settings_path
    end
  rescue StandardError => e
    flash[:danger] = I18n.t('settings.products.messages.destroyed_error')
    redirect_to settings_path
  end

  private

  def set_product
    @product = Product.find_by(id: params[:id] || params[:product_id])
  end

  def product_params
    params.require(:product).permit(Product.allowed_attributes)
  end
end
