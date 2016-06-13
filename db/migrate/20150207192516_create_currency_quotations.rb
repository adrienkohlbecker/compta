# frozen_string_literal: true
class CreateCurrencyQuotations < ActiveRecord::Migration
  def change
    create_table :currency_quotations do |t|
      t.integer :currency_id
      t.date :date
      t.decimal :value, precision: 15, scale: 5

      t.timestamps null: false
    end

    add_foreign_key :currency_quotations, :currencies
  end
end
