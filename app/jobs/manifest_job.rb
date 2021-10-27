class ManifestJob < ApplicationJob
  queue_as :manifest

  def perform(data)
    data[:pickups].each do |pickup|
      ManifestService.new(provider: pickup[:provider],
                          manifest_uuid: pickup[:manifest_uuid],
                          pickup_id: pickup[:id]).generate_pdf
    end
  end
end
