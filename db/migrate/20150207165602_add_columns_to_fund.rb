# frozen_string_literal: true
class AddColumnsToFund < ActiveRecord::Migration
  def change
    add_column :funds, :url, :string
  end
end
