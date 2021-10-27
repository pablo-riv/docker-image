class InsertTablePlans < ActiveRecord::Migration[5.0]
  def self.up
    Plan.create(id: 1, name: 'Starter', description: 'Plan Básico costo 0', is_active: false, floor_price: 0.0, total_discount: 0.0, unit_price: 'uf')
    Plan.create(id: 2, name: 'Despega', description: 'Plan Emprendedor', is_active: true, floor_price: 0.9, total_discount: 4.0, unit_price: 'uf')
    Plan.create(id: 3, name: 'Acelera', description: 'Plan Pyme', is_active: true, floor_price: 4.0, total_discount: 8.0, unit_price: 'uf')
    Plan.create(id: 4, name: 'Enterprise', description: 'Plan Empresarial', is_active: false, floor_price: 0.0, total_discount: 0.0, unit_price: 'uf')
    Plan.create(id: 5, name: 'Corporativo', description: 'Plan Corporación', is_active: false, floor_price: 0.0, total_discount: 0.0, unit_price: 'uf')
  end

  def self.down
    Plan.delete_all
  end
end
