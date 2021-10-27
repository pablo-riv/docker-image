class DropOutService
  def initialize(attributes)
    @attributes = attributes
  end

  def send_alert
    send_slack
    send_email if salesman.present?
  rescue StandardError => e
    render_rescue(e)
  end

  private

  def send_slack
    Slack::DropOut.new({}).alert(message: drop_out.deactivated ? deactivation_message : reactivation_message)
  end

  def send_email
    Publisher.publish("drop_out_notifications", salesman: salesman, company: company, drop_out: drop_out)

  end

  def drop_out
    @attributes[:drop_out]
  end

  def salesman
    @attributes[:salesman]
  end

  def company
    @attributes[:company]
  end

  def deactivation_message
    "Hola <@#{salesman.try(:slack_id)}>! "\
    "Cliente <https://staff.shipit.cl/administration/companies/#{company.id}|#{company.name}> ha desactivado su cuenta.\n"\
    "*Fecha de desactivación:* #{drop_out.created_at}.\n"\
    "*Motivo de desactivación:* #{drop_out.other_reason.present? ? drop_out.other_reason : drop_out.reason}.\n"\
    "*Comentarios:* #{drop_out.details}."
  end

  def reactivation_message
    "Hola <@#{salesman.try(:slack_id)}>! "\
    "Cliente <https://staff.shipit.cl/administration/companies/#{company.id}|#{company.name}> ha reactivado su cuenta.\n"\
    "*Fecha de reactivación*: #{drop_out.updated_at}.\n"\
    "*Fecha de desactivación*: #{drop_out.created_at}.\n"\
    "*Motivo de desactivación*: #{drop_out.other_reason.present? ? drop_out.other_reason : drop_out.reason}.\n"\
    "*Comentarios*: #{drop_out.details}."
  end

  def render_rescue(error)
    Rails.logger.info "ERROR: #{error.message}\n#{error.backtrace[0]}".cyan.swap
  end
end
