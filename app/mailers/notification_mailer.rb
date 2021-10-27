class NotificationMailer < ApplicationMailer
  default from: 'Plaforma <no-reply@shipit.cl>'

  def generic(subject, message, client)
    @message = message
    @client = client
    mail(to: 'alertassistemas@shipit.cl', bcc: ['hirochi@shipit.cl', 'michel@shipit.cl', 'nelson@shipit.cl'], subject: subject) do |format|
      format.mjml { render 'generic' }
    end
  end

  def failed_to_client(subject, client, message)
    @message = message
    mail(to: client.email, bbc: 'alertasenvios@shipit.cl', subject: subject) do |format|
      format.mjml { render 'failed_to_client' }
    end
  end

  def broke_stock(data)
    @sku = data['sku']
    mail(from: 'bot@shipit.cl', to: data['email'], bcc: ['hirochi@shipit.cl'], subject: "¡Se agotaron las unidades del SKU: #{@sku['name']}! 😧") do |format|
      format.mjml { render 'broke_stock' }
    end
  end

  def security_stock(data)
    @sku = data['sku']
    mail(from: 'bot@shipit.cl', to: data['email'], bcc: ['hirochi@shipit.cl'], subject: "¡Se están agotando las unidades del SKU: #{@sku['name']}! 😧") do |format|
      format.mjml { render 'security_stock' }
    end
  end

  def ff_orders_status(data)
    @inventories_success = data[:inventories_success]
    @inventories_errors = data[:inventories_errors]
    mail(from: 'bot@shipit.cl', to: 'fulfillment@shipit.cl', bcc: ['hirochi@shipit.cl', 'francisco@shipit.cl'], subject: "Estado de Ordenes de Cliente: #{data[:company_name]} - Company_id: #{data[:company_id]}") do |format|
      format.mjml { render 'ff_orders_status' }
    end
  end

  def courier_indirect_failure(data)
    @courier = data[:courier]
    @package = data[:package]
    @destiny = data[:destiny].upcase
    mail(from: 'bot@shipit.cl', to: data[:email], bcc: ['hirochi@shipit.cl'], subject: "Pedido #{data[:package]} cancelado: Destino Indirecto") do |format|
      format.mjml { render 'courier_indirect_failure' }
    end
  end
end
