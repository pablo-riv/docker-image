json.sellers do
  json.array! @sellers do |seller|
    seller.each do |name, configuration|
      json.name name
      json.configuration configuration
    end
  end
end
