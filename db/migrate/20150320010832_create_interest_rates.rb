# frozen_string_literal: true
class CreateInterestRates < ActiveRecord::Migration
  def change
    create_table :interest_rates do |t|
      t.integer :object_id
      t.string :object_type
      t.decimal :rate, precision: 15, scale: 5
      t.date :from
      t.date :to

      t.timestamps null: false
    end
  end
end
