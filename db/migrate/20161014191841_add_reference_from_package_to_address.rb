class AddReferenceFromPackageToAddress < ActiveRecord::Migration[5.0]
  def change
    add_reference :addresses, :package
  end
end
