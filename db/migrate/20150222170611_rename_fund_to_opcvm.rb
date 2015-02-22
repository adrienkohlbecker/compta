class RenameFundToOpcvm < ActiveRecord::Migration
  def change
    rename_table :funds, :opcvm_funds
  end
end
