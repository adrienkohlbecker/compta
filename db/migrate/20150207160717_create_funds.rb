class CreateFunds < ActiveRecord::Migration
  def change
    create_table :funds do |t|
      t.string :isin
      t.string :name
      t.string :boursorama_id

      t.timestamps null: false
    end
  end
end
