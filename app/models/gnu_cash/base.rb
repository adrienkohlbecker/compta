class GnuCash::Base < ActiveRecord::Base
  establish_connection(
    adapter: 'sqlite3',
    database: '/Users/adrien/Dropbox/Applications/Gnucash/compta.gnucash'
  )
  self.abstract_class = true
end
