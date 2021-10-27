FactoryBot.define do
  factory :area do
    name { 'area 76543' }
    coords { [{"latitude"=>"-33.61216666575461", "longitude"=>"-70.72021722793579"},
              {"latitude"=>"-33.61370347454426", "longitude"=>"-70.72100043296814"},
              {"latitude"=>"-33.61438252086236", "longitude"=>"-70.7189404964447"},
              {"latitude"=>"-33.61240791080787", "longitude"=>"-70.718092918396"}] }
    color { '#1e90ff' }
    hope { 0.0 }
  end
end