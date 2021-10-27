class APIConstraints
  attr_accessor :version

  def initialize(options)
    @default = options[:default]
    @version = options[:version]
  end

  def matches?(req)
    @default || req.headers['Accept'].include?("application/vnd.shipit.v#{@version}")
  rescue => e
    @version = 4
    @default = false
  end
end
