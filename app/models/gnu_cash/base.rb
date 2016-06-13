# frozen_string_literal: true
class GnuCash::Base < ActiveRecord::Base
  establish_connection(
    adapter: 'sqlite3',
    database: '/gnucash/compta.gnucash'
  )
  self.abstract_class = true
end
