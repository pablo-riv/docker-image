class DropOut < ApplicationRecord
  belongs_to :account

  after_create :send_alert
  after_update :send_alert, unless: [:deactivated]

  validates_associated :account

  def send_alert
    @account = account
    @company = account.current_company
    @salesman = Salesman.find_by(id: @company.first_owner_id)
    DropOutService.new(drop_out: self,
                       account: @account,
                       company: @company,
                       salesman: @salesman).send_alert
  end
end
