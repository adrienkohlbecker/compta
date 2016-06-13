# frozen_string_literal: true
class CreatePortfolios < ActiveRecord::Migration
  def change
    create_table :portfolios do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
