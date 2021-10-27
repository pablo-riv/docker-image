class AddReferenesBetweenCountryAndRegion < ActiveRecord::Migration[5.0]
  def change
    add_reference :regions, :country
  end
end
