json.array!(@services) do |service|
  json.extract! service, :id, :name, :price, :created_at, :updated_at
end
