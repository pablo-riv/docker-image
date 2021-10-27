class CouriersWithSlug < ActiveRecord::Migration[5.0]
  def change
    system('rake courier:setup')

    add_column :couriers, :slug, :string, null: true, limit: 64

    say "Updating Courriers slugs"
    Courier.update(
      [1,2,3,4],
      [
        {slug: "dhl"},
        {slug: "chilexpress"},
        {slug: "starken"},
        {slug: "correos_de_chile"}
      ]
    )    
  end
end
