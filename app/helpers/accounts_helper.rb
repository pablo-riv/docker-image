module AccountsHelper
  def account_first_name(account)
    return account.person.try(:first_name)
  end

  def account_last_name(account)
    return account.person.try(:last_name)
  end
end
