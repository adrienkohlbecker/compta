class RenameBfUrl < ActiveRecord::Migration
  def change
    rename_column :currencies, :bf_url, :bf_id
  end
end
