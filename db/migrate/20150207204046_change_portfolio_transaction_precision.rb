class ChangePortfolioTransactionPrecision < ActiveRecord::Migration
  def up
    change_column :portfolio_transactions, :shares, :decimal, precision: 15, scale: 5
    change_column :portfolio_transactions, :amount, :decimal, precision: 15, scale: 5
  end
  def down
    change_column :portfolio_transactions, :shares, :decimal, precision: 10, scale: 5
    change_column :portfolio_transactions, :amount, :decimal, precision: 10, scale: 5
  end
end
