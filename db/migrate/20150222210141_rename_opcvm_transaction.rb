class RenameOpcvmTransaction < ActiveRecord::Migration
  def change
    rename_table :opcvm_quotations, :fund_quotations
    add_column :fund_quotations, :fund_type, :string
    rename_column :fund_quotations, :opcvm_fund_id, :fund_id
    remove_foreign_key :fund_quotations, column: :fund_id
  end
end
