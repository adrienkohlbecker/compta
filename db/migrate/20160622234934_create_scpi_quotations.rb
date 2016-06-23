class CreateScpiQuotations < ActiveRecord::Migration
  def change
    create_table :scpi_quotations do |t|
      t.decimal :value_original, precision: 15, scale: 5, null: false
      t.string :value_currency, null: false
      t.date :value_date, null: false
      t.decimal :subscription_value_original, precision: 15, scale: 5, null: false
      t.string :subscription_value_currency, null: false
      t.date :subscription_value_date, null: false
      t.date :date, null: false
      t.integer :scpi_fund_id, null: false
      t.timestamps null: false
    end
    add_foreign_key :scpi_quotations, :scpi_funds
  end
end
