def check_couple_split
  _logger = ActiveRecord::Base.logger
  ActiveRecord::Base.logger = nil

  GnuCash::Account.where(name: 'Marie').includes(parent: {splits: {tx: :splits}}, splits: {tx: :splits}).find_each do |account|
    txs = (account.splits.map(&:tx) + account.parent.splits.map(&:tx)).uniq
    txs.each do |tx|
      total_half = 0
      total_full = 0

      tx.splits.each do |split|
        if split.account_guid == account.guid
          total_half += split.value
        end

        if split.account_guid == account.parent.guid
          total_full += split.value
        end
      end

      if total_full != - total_half * 2
        puts "#{account.parent.identifier} #{tx.post_date} #{tx.description} #{total_full.to_f} #{total_half.to_f}"
      end
    end
  end

  ActiveRecord::Base.logger = _logger
  nil
end
