class RenameFundQuotation < ActiveRecord::Migration
  def change
    rename_table :fund_quotations, :opcvm_quotations
    remove_column :opcvm_quotations, :fund_type, :string
    rename_column :opcvm_quotations, :fund_id, :opcvm_fund_id
    add_foreign_key :opcvm_quotations, :opcvm_funds
  end
end
