class AddIndexOnInterestRate < ActiveRecord::Migration
  def up
    execute %(
      CREATE INDEX index_interest_rates_on_object_type_and_object_id
        ON interest_rates
        USING btree
        (object_type, object_id);
    )
  end
  def down
    execute 'DROP INDEX index_interest_rates_on_object_type_and_object_id;'
  end
end
