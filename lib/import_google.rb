# frozen_string_literal: true

# # frozen_string_literal: true

# list = CSV.foreach('transactions.csv', headers: true, col_sep: ';').map { |r| [r['Categorie'], r['Base']] }.flatten.sort.uniq
# accounts = []
# accounts += list.map { |i| i.split(':')[0, 1].join(':') }.sort.uniq
# accounts += list.map { |i| i.split(':')[0, 2].join(':') }.sort.uniq
# accounts += list.map { |i| i.split(':')[0, 3].join(':') }.sort.uniq
# accounts += list.map { |i| i.split(':')[0, 4].join(':') }.sort.uniq
# accounts += list.map { |i| i.split(':')[0, 5].join(':') }.sort.uniq
# accounts += list.map { |i| i.split(':')[0, 6].join(':') }.sort.uniq
# accounts += list.map { |i| i.split(':')[0, 7].join(':') }.sort.uniq
# accounts = accounts.flatten.sort.uniq

# puts accounts

# # type  full_name  name  code  description  color  notes  commoditym  commodityn  hidden  tax  place_holder
# # EXPENSE  Aliments  Aliments      Not Set    EUR  CURRENCY  F  F  F

# CSV.open('accounts.csv', 'wb', col_sep: ';') do |csv|
#   accounts.each do |act|
#     name = act.split(':').last
#     cur = %w[KRW LAK PHP THB USD VND CNY].include?(name) ? name : 'EUR'
#     type = act.include?('WIP:Bank') ? 'BANK' : 'EXPENSE'
#     csv << [type, act, act.split(':').last, '', '', 'Not Set', '', cur, 'CURRENCY', 'F', 'F', 'F']
#   end
# end

@act_index = {}
@act_index[''] = GnuCash::Account.where(account_type: 'ROOT').first

def find_act(name)
  @act_index[name] ||= begin
    parent_name = name.include?(':') ? name.split(':')[0..-2].join(':') : ''
    my_name = name.split(':').last

    GnuCash::Account.where(name: my_name, parent: find_act(parent_name)).first
  end
end

@curs = {}
def find_curr(name)
  @curs[name] ||= GnuCash::Commodity.where(mnemonic: name).first
end

i = 0
CSV.foreach('transactions.csv', headers: true, col_sep: ';') do |rec|
  base = find_act(rec[0])
  dest = find_act(rec[2])
  date = Time.strptime(rec[1] + ' 120000', '%d/%m/%Y %H%M%S')
  amount = rec[3].tr(',', '.').to_r
  desc = rec[4]
  cur = %w[KRW LAK PHP THB USD VND CNY].include?(rec[0].split(':').last) ? rec[0].split(':').last : 'EUR'

  tr = GnuCash::Transaction.create!(
    guid: SecureRandom.hex(16),
    currency_guid: find_curr(cur).guid,
    num: '',
    post_date: date.strftime('%Y%m%d%H%M%S'),
    enter_date: (Time.now - i.seconds).strftime('%Y%m%d%H%M%S'),
    description: desc
  )

  GnuCash::Split.create!(
    guid: SecureRandom.hex(16),
    tx_guid: tr.guid,
    account_guid: base.guid,
    memo: '',
    action: '',
    reconcile_state: 'n',
    reconcile_date: '19700101000000',
    value_num: amount.numerator,
    value_denom: amount.denominator,
    quantity_num: amount.numerator,
    quantity_denom: amount.denominator,
    lot_guid: nil
  )

  GnuCash::Split.create!(
    guid: SecureRandom.hex(16),
    tx_guid: tr.guid,
    account_guid: dest.guid,
    memo: '',
    action: '',
    reconcile_state: 'n',
    reconcile_date: '19700101000000',
    value_num: -amount.numerator,
    value_denom: amount.denominator,
    quantity_num: -amount.numerator,
    quantity_denom: amount.denominator,
    lot_guid: nil
  )

  i += 1
end
