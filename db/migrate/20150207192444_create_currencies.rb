# frozen_string_literal: true
class CreateCurrencies < ActiveRecord::Migration
  def change
    create_table :currencies do |t|
      t.string :name
      t.string :boursorama_id
      t.string :url

      t.timestamps null: false
    end
  end
end
