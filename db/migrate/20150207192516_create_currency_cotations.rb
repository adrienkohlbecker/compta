class CreateCurrencyCotations < ActiveRecord::Migration
  def change
    create_table :currency_cotations do |t|
      t.integer :currency_id
      t.date :date
      t.decimal :value, precision: 10, scale: 5

      t.timestamps null: false
    end

    add_foreign_key :currency_cotations, :currencies
  end
end
