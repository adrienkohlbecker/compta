# frozen_string_literal: true
class AddClosedFund < ActiveRecord::Migration
  def change
    add_column :opcvm_funds, :closed, :boolean, default: false, null: false
    add_column :opcvm_funds, :closed_date, :date
  end
end
