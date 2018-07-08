# frozen_string_literal: true
class GnuCash::Account < GnuCash::Base
  has_many :splits, foreign_key: :account_guid
  belongs_to :parent, foreign_key: :parent_guid, class_name: 'GnuCash::Account'
end
