class UploadDefaultLogoJob < ApplicationJob
  queue_as :default

  def perform(company)
    File.open("#{Rails.root}/app/assets/images/logo-shipit-light.png", 'rb') do |file|
      company.update(logo: file)
    end
  end
end
