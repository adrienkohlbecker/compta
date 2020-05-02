# frozen_string_literal: true

module GnuCash
  class Base < ActiveRecord::Base
    establish_connection(
      adapter: 'sqlite3',
      database: '/dataroom/Gnucash/compta.gnucash'
    )
    self.abstract_class = true
  end
end
