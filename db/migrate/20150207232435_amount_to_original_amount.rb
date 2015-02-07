class AmountToOriginalAmount < ActiveRecord::Migration
  def change
    rename_column :fund_cotations, :value, :value_original
    add_column :fund_cotations, :value_currency, :string
    add_column :fund_cotations, :value_date, :date
    rename_column :portfolio_transactions, :amount, :amount_original
    add_column :portfolio_transactions, :amount_currency, :string
    add_column :portfolio_transactions, :amount_date, :date
  end
end
