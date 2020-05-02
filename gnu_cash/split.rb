# frozen_string_literal: true

class GnuCash::Split < GnuCash::Base
  belongs_to :account, foreign_key: :account_guid
  belongs_to :tx, foreign_key: :tx_guid, class_name: 'GnuCash::Transaction'
end
