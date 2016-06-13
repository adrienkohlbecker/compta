# frozen_string_literal: true
class RemoveUrlColumn < ActiveRecord::Migration
  def change
    remove_column :opcvm_funds, :url, :string
  end
end
