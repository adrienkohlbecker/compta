class AddYearLength < ActiveRecord::Migration
  def change
    add_column :interest_rates, :year_length, :integer
  end
end
