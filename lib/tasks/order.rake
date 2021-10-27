namespace :order do
  desc 'Migrate orders'
  task migrate: :environment do
    ids = [637,1496,1922,632,116,981,1799,132,417,2859,2510,2878]
    Company.where(id: ids).find_each(batch_size: 5).each do |company|
      sellers = Setting.fullit(company.id).sellers_availables.map { |seller| seller.keys }.flatten
      next unless sellers.include?('shopify')

      skus = FulfillmentService.by_client(company.id)
      orders = OrderService.where(sent: false, company_id: 1, seller: 'shopify').map do |order_service|
        order_template = Orders::Generator.new(order_service.attributes.merge(company: company, account: company.current_account, skus: skus)).template
        data = Order.where(company_id: company.id, reference: order_template[:reference])
        next if data.present?

        order = Order.create(order_template)
        next if order.persisted?

        order
      end
    end
  end

  desc 'Delete duplicated'
  task delete: :environment do
    @data = []
    @errors = []
    Order.where(company_id: 1).each do |o|
      orders = Order.where.not(company_id: 1).where('LOWER(reference) = ?', o.reference.downcase)
      orders.each do |od|
        begin
          @data << od if od.destiny['email'].downcase.strip == o.destiny['email'].downcase.strip
        rescue => e
          @errors << od
        end
      end
    end
  end

  desc 'Update of orders with commune assigned to Mexico'
  task update_orders_with_wrong_commune: :environment do
    orders = Order.where(created_at: 8.days.ago..DateTime.current).includes(:company)
    communes = Country.find(1).communes
    errors = []
    orders.each do |order|
      destiny = order.destiny
      next errors << "no se encontro destino #{order.id}" unless destiny.present?

      unless communes.pluck(:id).include? destiny['commune_id']
        commune_name = destiny['commune_name'].presence || Commune.find(destiny['commune_id']).name
        commune = communes.find_by(name: commune_name)
        destiny['commune_id'] = commune.id
        destiny['commune_name'] = commune.name
        order.update_columns(destiny: destiny)
      end
    end
    puts errors
  end
end
