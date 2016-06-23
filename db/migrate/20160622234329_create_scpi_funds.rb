class CreateScpiFunds < ActiveRecord::Migration
  def change
    create_table :scpi_funds do |t|
      t.string :isin, null: false
      t.string :name, null: false
      t.string :currency, null: false
      t.timestamps null: false
    end
  end
end
