class UpdateCurrencyQuotationIndexes < ActiveRecord::Migration
  def change
    execute 'DROP INDEX index_currency_quotations_on_date;'
    execute 'ALTER INDEX index_currency_quotations_on_name_and_date RENAME TO index_currency_quotations_on_id_and_date;'
  end
  def down
    execute 'ALTER INDEX index_currency_quotations_on_id_and_date RENAME TO index_currency_quotations_on_name_and_date;'
    execute %(
    CREATE INDEX index_currency_quotations_on_date
      ON currency_quotations
      USING btree
      (date);
    )
  end
end
