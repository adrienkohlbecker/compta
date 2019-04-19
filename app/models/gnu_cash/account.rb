# frozen_string_literal: true
class GnuCash::Account < GnuCash::Base
  has_many :splits, foreign_key: :account_guid
  belongs_to :parent, foreign_key: :parent_guid, class_name: 'GnuCash::Account'
  has_many :children, foreign_key: :parent_guid, class_name: 'GnuCash::Account'
  belongs_to :commodity, foreign_key: :commodity_guid, class_name: 'GnuCash::Commodity'

  def self.root
    @root_account ||= GnuCash::Account.where(parent_guid: nil).first
  end

  def self.find_by_identifier(identifier)
    @query_index ||= {}

    if identifier == ''
      return root
    end

    if @query_index.has_key?(identifier)
      return @query_index[identifier]
    end

    parts = identifier.split(":")
    result = where(name: parts.last, parent_guid: find_by_identifier(parts[0...-1].join('::'))).first

    @query_index[identifier] = result

    result
  end

  def identifier
    @@identifier_index ||= {}

    if @@identifier_index.has_key?(guid)
      return @@identifier_index[guid]
    end

    if account_type == "ROOT"
      return ""
    end

    result = "#{parent.identifier}:#{name}"
    result.sub!(/^:/, '')

    @@identifier_index[guid] = result

    result
  end

  def deep_children
    children.map { |c| [c, c.deep_children]}.flatten
  end
end
