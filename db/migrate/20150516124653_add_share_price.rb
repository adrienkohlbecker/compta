# frozen_string_literal: true
class AddSharePrice < ActiveRecord::Migration
  def change
    add_column :portfolio_transactions, :shareprice_original, :decimal, precision: 15, scale: 5
    add_column :portfolio_transactions, :shareprice_date, :date
    add_column :portfolio_transactions, :shareprice_currency, :string
  end
end
