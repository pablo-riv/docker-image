namespace :shopify_api_version do
  desc 'Update shopify api versions'
  task update: :environment do
    versions = ShopifyAPI::ApiVersion.fetch_known_versions.to_a.map(&:first)
    stable_versions = versions.uniq.reject { |version| version == 'unstable' }
    unavailable_versions = ShopifyApiVersion.all.pluck(:name) - stable_versions
    stable_versions.each do |version|
      version = ShopifyApiVersion.find_or_create_by(name: version)
      version.update(active: true)
    end

    ShopifyApiVersion.where(name: unavailable_versions)
                     .update_all(active: false)
  end
end
