class CuttingHour < ApplicationRecord
  # ACT AS
  acts_as_paranoid

  belongs_to :cutting, polymorphic: true

  def by_service(service = :pp)
    case service.to_sym
    when :pp, :pick_and_pack then pick_and_pack_service
    when :ff, :fulfillment then fulfillment_service
    when :ll, :labelling then labelling_service
    else raise "Service #{service} not found"
    end
  rescue StandardError => e
    Rails.logger.error { "#{e.message}\n#{e.backtrace.first(2).join("\n")}".red.swap }
  end
end
