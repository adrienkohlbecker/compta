class CreateEuroFundInvestments < ActiveRecord::Migration
  def change
    create_table :euro_fund_investments do |t|
      t.integer :euro_fund_id
      t.decimal :amount_original, precision: 15, scale: 5
      t.string :amount_currency
      t.date :amount_date
      t.date :value_at
      t.integer :portfolio_id

      t.timestamps null: false
    end

    add_foreign_key :euro_fund_investments, :portfolios
    add_foreign_key :euro_fund_investments, :euro_funds
  end
end
