class AddBndFundId < ActiveRecord::Migration
  def change
    add_column :opcvm_funds, :bnd_fund_id, :integer
  end
end
