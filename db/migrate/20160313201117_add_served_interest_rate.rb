# frozen_string_literal: true
class AddServedInterestRate < ActiveRecord::Migration
  def change
    add_column :interest_rates, :served_rate, :decimal, precision: 15, scale: 5
    rename_column :interest_rates, :rate, :minimal_rate
  end
end
