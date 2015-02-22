class AddPolymorphism < ActiveRecord::Migration
  def change
    add_column :fund_quotations, :fund_type, :string
    add_column :portfolio_transactions, :fund_type, :string
    remove_foreign_key "fund_quotations", column: "fund_id"
    remove_foreign_key "portfolio_transactions", column: "fund_id"
  end
end
