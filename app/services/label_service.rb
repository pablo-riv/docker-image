class LabelService
  attr_accessor :packages

  def initialize(packages, company, account)
    @packages = packages
    @company = company
  end

  def pdf
    generate
    client = ::Aws::S3::Resource.new
    bucket = client.bucket('shipit-avery-tickets')
    dir = bucket.object("client-avery/#{Time.current.year}/#{Time.current.month}/#{Time.current.day}/#{@company.name}.pdf")
    dir.put(body: File.read("#{Rails.root}/public/pdf/#{@company.name.gsub('/', '-')}.pdf"), content_type: 'application/pdf', acl: 'public-read')

    dir.public_url
  end

  private

  def generate
    files = CombinePDF.new
    @packages.reject { |p| ['', nil].include?(p.pack_pdf) }.each do |package|
      open(package.pack_pdf) do |file|
        files << CombinePDF.load(file.path)
      end
    end
    files.save "#{Rails.root}/public/pdf/#{@company.name.gsub('/', '-')}.pdf"
  end
end
