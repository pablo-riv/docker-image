module Setup
  class CompaniesController < ApplicationController
    layout 'setup'

    before_action :set_company, only: [:edit, :update]
    before_action :set_person, only: [:edit, :update]

    def edit
      @communes = Commune.where(is_available: true).order(name: :asc)
    end

    def update
      raise unless Company.setup(params[:company], current_account)
      render json: { state: :ok }, status: :ok
    rescue => e
      puts e.message.to_s.red.swap
      Slack::Ti.new({}, {}).alert('', "Cliente #{@company.name} No pudo actualizar su información error: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
      render json: { state: :error, message: 'No se pudo actualizar la informacion.' }, status: :bad_request
    end

    private

    def set_company
      @company = current_account.entity_specific
    rescue => e
      puts e.message.red
    end

    def set_person
      @person = current_account.person
    end
  end
end
