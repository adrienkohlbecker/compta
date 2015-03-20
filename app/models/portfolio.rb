# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Portfolio < ActiveRecord::Base
  has_many :transactions, class_name: 'PortfolioTransaction'
  has_many :euro_fund_investments

  def currency
    "EUR"
  end

  def append_opcvm_transaction(fund_id:, shares:, amount:, date:)

    transactions.create(
      fund: OpcvmFund.find(fund_id),
      shares: shares,
      amount: Amount.new(amount, currency, date),
      done_at: date
    )

  end

  def append_euro_transaction(fund_id:, amount:, date:)

    transactions.create(
      fund: EuroFund.find(fund_id),
      shares: nil,
      amount: Amount.new(amount, currency, date),
      done_at: date
    )

  end

  def print_list

    items = {}
    OpcvmFund.all.each do |fund|

      shares = PortfolioTransaction.where(fund: fund).pluck(:shares).reduce(:+)
      invested = PortfolioTransaction.where(fund: fund).map(&:amount).reduce(:+).to_eur
      current_value = (fund.quotation_at(Date.today) * shares).to_eur

      items[fund.name] = {
        '#id': fund.id,
        name: fund.name,
        isin: fund.isin,
        shares: shares,
        invested: invested,
        value: current_value,
        pv: current_value - invested
      }

    end
    EuroFund.all.each do |fund|

      invested = PortfolioTransaction.where(fund: fund, category: 'Virement').map(&:amount).reduce(:+)
      actual_pv = PortfolioTransaction.where(fund: fund).where.not(category: 'Virement').map(&:amount).reduce(:+)

      rate = fund.current_interest_rate

      value_at_beginning_of_year = PortfolioTransaction.where(fund: fund).where('done_at < ?', Date.today.beginning_of_year).map(&:amount).reduce(:+)
      latent_pv = value_at_beginning_of_year * ((1 + rate) ** ((Date.today - Date.today.beginning_of_year - 1) / 365.0) - 1)

      PortfolioTransaction.where(fund: fund).where('done_at >= ?', Date.today.beginning_of_year).order('done_at ASC').each do |t|
        latent_pv += t.amount * ((1 + rate) ** ((Date.today - t.done_at - 1) / 365.0) - 1)
      end
      pv = latent_pv + actual_pv

      items[fund.name] = {
        '#id': fund.id,
        name: fund.name,
        isin: nil,
        shares: nil,
        invested: invested,
        value: invested + pv,
        pv: pv
      }

    end

    puts Hirb::Helpers::AutoTable.render(items.values)

    invested = Amount.new(0, "EUR", Date.today)
    value = Amount.new(0, "EUR", Date.today)
    pv = Amount.new(0, "EUR", Date.today)

    items.values.each do |h|
      invested += h[:invested]
      value += h[:value]
      pv += h[:pv]
    end

    puts "Invested: #{invested} / Current: #{value} / PV: #{pv}"

  end
end
