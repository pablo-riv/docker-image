namespace :condition do
  desc 'Populate condition table for checkout rules'
  task add_conditions: :environment do
    conditions = [
      'Menor que',
      'Menor o igual que',
      'Mayor que',
      'Mayor o igual que',
      'Igual que',
      'Distinto de'
    ]
    conditions.map.with_index(1) do |condition, id|
      Condition.create(id: id, name: condition)
    end
  end
end
