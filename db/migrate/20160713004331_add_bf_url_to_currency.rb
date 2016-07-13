class AddBfUrlToCurrency < ActiveRecord::Migration
  def change
    add_column :currencies, :bf_url, :string
  end
end
