class AddPreferenceToCompany < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :preferences, :json, default: { email: { color: { background_header: '#00c2de',
                                                                             background_footer: '#00c2de',
                                                                             font_color_footer: '#ffffff' } } }
  end
end
