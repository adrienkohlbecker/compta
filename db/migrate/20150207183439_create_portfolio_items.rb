# frozen_string_literal: true
class CreatePortfolioItems < ActiveRecord::Migration
  def change
    create_table :portfolio_transactions do |t|
      t.integer :fund_id
      t.decimal :shares, precision: 10, scale: 5
      t.integer :portfolio_id
      t.date :done_at
      t.decimal :amount, precision: 10, scale: 5

      t.timestamps null: false
    end

    add_foreign_key :portfolio_transactions, :funds
    add_foreign_key :portfolio_transactions, :portfolios
  end
end
