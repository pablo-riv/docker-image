class V::V4::ProductsController < V::ApplicationController
  before_action :set_company
  before_action :set_products, only: %i(index)
  before_action :set_product, only: %i(show update destroy)

  def index
    respond_with(@products)
  end

  def show
    respond_with(@product)
  end

  def create
    Product.transaction do
      @product = @company.products.new(product_params)
      image = @product.upload_image(params[:product][:image])
      @product.assign_attributes(image: image)
      raise unless @product.save

      respond_with(@product)
    end
  rescue => e
    render_rescue(e)
  end

  def update
    Product.transaction do
      if params[:product][:image].include?('shipit-platform.s3')
        product_params.except!(:image)
      else
        image = @product.upload_image(params[:product][:image])
        @product.assign_attributes(image: image)
      end
      raise unless @product.update(product_params)

      respond_with(@product)
    end
  rescue => e
    render_rescue(e)
  end

  def destroy
    Product.transaction do
      raise unless @product.update(archive: true)

      render json: { state: :ok }, status: :ok
    end
  rescue => e
    render_rescue(e)
  end

  private

  def set_company
    @company = company
  end

  def render_rescue(exception)
    Rails.logger.info { "ERROR: #{exception.message}\nBUGTRACE#{exception.backtrace[0]}".red.swap }
    render json: { message: exception.message, state: :error }, status: :bad_request
  end

  def set_product
    @product = @company.products.find_by(id: params[:id])
  end

  def set_products
    @products = @company.products
  end

  def product_params
    params.require(:product).permit(Product.allowed_attributes)
  end
end
