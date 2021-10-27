module Help
  class ZendeskUser < ZendeskClient
    attr_accessor :account, :user

    def initialize(account)
      @account = account
      @user = {}
      super() # need to specify braces or raise an exception wtf?
    end

    def find
      search = client.users.search(query: account.email)
      @user = search[0]
    end

    def create
      @user = client.users.create(email: account.email,
                                  name: full_name,
                                  verified: true)
    end

    private

    def full_name
      @account.full_name.strip == '' ? @account.email : @account.full_name
    end
  end
end
