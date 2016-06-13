# frozen_string_literal: true
class AddSocialTaxRate < ActiveRecord::Migration
  def change
    add_column :interest_rates, :social_tax_rate, :decimal, precision: 15, scale: 5
  end
end
