class ChangeFundCotationPrecision < ActiveRecord::Migration
  def up
    change_column :fund_cotations, :value, :decimal, precision: 15, scale: 5
  end
  def down
    change_column :fund_cotations, :value, :decimal, precision: 10, scale: 5
  end
end
