class Insurance < ApplicationRecord
  # RELATIONS
  belongs_to :package

  # CALLBACKS
  after_create :slack_alert

  # SCOPES
  default_scope { where(archive: false) }

  def self.allowed_attributes
    %i(ticket_amount ticket_number price detail extra package_id)
  end

  def self.allowed_edit_attributes
    %i(ticket_amount ticket_number price detail extra)
  end

  private

  def slack_alert
    return if ticket_amount.nil?
    return if ticket_amount.try(:to_i) < 1_000_000
    return unless extra

    company = package.company
    kam = Salesman.find_by(id: company.first_owner_id)
    message = "Atención <@#{kam.try(:slack_id)}|kam.full_name>!\n"\
              "Tenemos un envío asegurado por #{ActionController::Base.helpers.number_to_currency(ticket_amount)}\n"\
              "Cliente #{company.name} para el envío: <https://staff.shipit.cl/administration/packages/#{package_id}|#{package_id}>"

    Slack::Insurance.new({}).alert(message: message)
  rescue => e
    Rails.logger.info "ERROR: #{e.message}\n#{e.backtrace[0]}".cyan.swap
    Rails.logger.info "TICKET AMOUNT: #{self.try(:ticket_amount)}".cyan.swap
  end
end
