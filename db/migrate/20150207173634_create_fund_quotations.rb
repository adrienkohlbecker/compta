# frozen_string_literal: true
class CreateFundQuotations < ActiveRecord::Migration
  def change
    create_table :fund_quotations do |t|
      t.integer :fund_id
      t.decimal :value, precision: 10, scale: 2
      t.date :date

      t.timestamps null: false
    end

    add_foreign_key :fund_quotations, :funds
  end
end
