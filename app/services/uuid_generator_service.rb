class UuidGeneratorService
  require 'digest'
  class << self
    def pickup_uuid(pickup)
      concatenated_str = "#{pickup.branch_office_id}-" \
                         "#{pickup.schedule['date']}-" \
                         "#{pickup.provider}-" \
                         "#{pickup.origin_id.presence || 'default'}-" \
                         "#{pickup.pick_and_pack_id}"
      Digest::SHA2.new(256).hexdigest(concatenated_str)
    end

    def manifest_uuid(pickup)
      concatenated_str = "#{DateTime.current.strftime('%Y-%m-%d %H:%M:%S.%L')}-" \
                         "#{pickup.packages.size}"
      Digest::SHA2.new(256).hexdigest(concatenated_str)
    end
  end
end
