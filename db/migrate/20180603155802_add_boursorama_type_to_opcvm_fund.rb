class AddBoursoramaTypeToOpcvmFund < ActiveRecord::Migration
  def change
    add_column :opcvm_funds, :boursorama_type, :string
  end
end
