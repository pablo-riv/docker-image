module Rejectable
  extend ActiveSupport::Concern

  included do
    before_action :verify_debtor_account

    def verify_debtor_account
      return unless current_account.present?
  
      if current_account.entity_specific.class == Company
        branch_office_redirect
      else
        headquarter_redirect
      end
    end
  
    def branch_office_redirect
      @debtor = current_account.entity_specific.debtors
      return if params[:controller] == 'debtors'
  
      if @debtor && !%w[charges accounts/sessions].include?(params[:controller])
        if current_account.current_company.platform_version == 2
          redirect_to debtors_path
        else
          render json: { state: :error, message: 'Tu cuenta se encuentra bloqueada por no pago. Te pedimos regularizar la situación y/o escribirnos a cobranza@shipit.cl', debtor: @debtor }, status: :bad_request
        end
      end
    end
  
    def headquarter_redirect
      @debtor = current_account.entity_specific.company.debtors
      return if params[:controller] == 'headquarter/debtors'
  
      redirect_to headquarter_debtors_path if @debtor && !%w[accounts/sessions].include?(params[:controller])
    end
  end
end