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

    items = []
    OpcvmFund.order(:id).each do |fund|

      shares = PortfolioTransaction.where(fund: fund).pluck(:shares).reduce(:+) || 0
      invested = PortfolioTransaction.where(fund: fund, category: "Virement").map(&:amount).reduce(:+).try(:to_eur) || 0
      current_value = (fund.quotation_at(Date.today) * shares).to_eur

      items << {
        '#id': fund.id,
        name: fund.name,
        isin: fund.isin,
        shares: shares,
        invested: invested,
        value: current_value,
        pv: current_value - invested,
        '%': (current_value / invested * 100 - 100).round(2)
      }

    end
    EuroFund.order(:id).each do |fund|

      invested = PortfolioTransaction.where(fund: fund, category: 'Virement').map(&:amount).reduce(:+)
      actual_pv = PortfolioTransaction.where(fund: fund).where.not(category: 'Virement').map(&:amount).reduce(:+)

      rate = fund.current_interest_rate

      value_at_beginning_of_year = PortfolioTransaction.where(fund: fund).where('done_at < ?', Date.today.beginning_of_year).map(&:amount).reduce(:+)
      latent_pv = value_at_beginning_of_year * ((1 + rate) ** ((Date.today - Date.today.beginning_of_year - 1) / 365.0) - 1)

      PortfolioTransaction.where(fund: fund).where('done_at >= ?', Date.today.beginning_of_year).order('done_at ASC').each do |t|
        latent_pv += t.amount * ((1 + rate) ** ((Date.today - t.done_at - 1) / 365.0) - 1)
      end
      pv = latent_pv + actual_pv

      items << {
        '#id': fund.id,
        name: fund.name,
        isin: nil,
        shares: nil,
        invested: invested,
        value: invested + pv,
        pv: pv,
        '%': ((invested + pv) / invested * 100 - 100).round(2)
      }

    end

    puts Hirb::Helpers::AutoTable.render(items)

    invested = Amount.new(0, "EUR", Date.today)
    value = Amount.new(0, "EUR", Date.today)
    pv = Amount.new(0, "EUR", Date.today)

    items.each do |h|
      invested += h[:invested]
      value += h[:value]
      pv += h[:pv]
    end

    puts "Invested: #{invested} / Current: #{value} / PV: #{pv} / %: #{(value / invested * 100 - 100).round(2)}"

  end

  def print_transactions

    items = []

    transactions.includes(:fund).order(:done_at, :fund_type, :fund_id).each do |t|

      items << {
        '#id': t.id,
        date: t.done_at,
        name: t.fund.name,
        isin: t.fund.try(:isin),
        shares: t.shares.try(:round, 4),
        amount: t.amount,
        shareprice: t.shareprice,
        category: t.category
      }

    end

    puts Hirb::Helpers::AutoTable.render(items)

  end

  def invested_at(date)
    transactions.where(fund_type: "OpcvmFund", category: "Virement").where("done_at <= ?", date).map(&:amount).reduce(:+)
  end

  def value_at(date)
    transactions.where(fund_type: "OpcvmFund").where("done_at <= ?", date).map{|t| t.shares * t.fund.quotation_at(date).to_eur}.reduce(:+)
  end

  def print_performance

    start_date = transactions.order("done_at ASC").first.done_at
    end_date = Date.today

    items = []

    (start_date..end_date).each do |date|

      value = value_at(date)
      invested = invested_at(date)
      pv = value - invested

      items << {
        date: date,
        invested: invested,
        value: value.round(2),
        pv: pv.round(2)
      }
    end

    puts Hirb::Helpers::AutoTable.render(items)

  end
end
