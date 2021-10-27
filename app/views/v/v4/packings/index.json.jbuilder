json.array! @packings do |packing|
  json.extract! packing, :id, :name, :sizes, :weight, :default, :created_at, :updated_at
end 