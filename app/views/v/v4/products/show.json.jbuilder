json.extract! @product, :id, :name, :sizes, :weight, :description, :created_at, :updated_at
json.image @product.image.url(:small).gsub('//s3', 'https://s3-us-west-2')