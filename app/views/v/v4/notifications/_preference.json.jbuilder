json.extract! company, :id, :preferences
if company.logo.present?
  json.logo company.logo.url(:small).gsub('//s3', 'https://s3-us-west-2')
else
  json.logo ''
end
