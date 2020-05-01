def add(doc, account: nil, date: nil, amount: 0, tax: 0, security: "", shares: 0, note: "", typ: "")
  raise "Invalid argument" if account.blank? || date.blank? || amount.blank? || typ.blank?

  node = %(
    <account-transaction>
      <date>#{date.strftime('%Y-%m-%d')}T00:00</date>
      <currencyCode>USD</currencyCode>
      <amount>#{(amount * 100).to_i}</amount>
  )

  if !security.blank?
    index = doc.css('securities > security').index(doc.css('securities > security').find {|n| n.css('> name').text() == security})
    node += %(
      <security reference="../../../../../securities/security[#{index+1}]"/>
    )
  end

  node += %(
      <shares>#{(shares * 1000000).to_i}</shares>
  )

  if !note.blank?
    node += %(
      <note>#{note}</note>
    )
  end

  if tax != 0
    node += %(
      <units>
        <unit type="TAX">
          <amount currency="USD" amount="#{(tax * 100).to_i}"/>
        </unit>
      </units>
    )
  end

  node += %(
      <type>#{typ}</type>
    </account-transaction>
  )

  account_node = doc.css('accounts > account').find{|n| n.css('> name').text() == account }
  account_node.css('> transactions').first.add_child(node)
end

def add_deposit(doc, account: nil, date: nil, amount: 0, note: "")
  add(doc, account: account, date: date, amount: amount, note: note, typ: "DEPOSIT")
end

def add_removal(doc, account: nil, date: nil, amount: 0, note: "")
  add(doc, account: account, date: date, amount: amount, note: note, typ: "REMOVAL")
end

def add_interest(doc, account: nil, date: nil, amount: 0, tax: 0, note: "")
  add(doc, account: account, date: date, amount: amount, tax: tax, note: note, typ: "INTEREST")
end

def add_interest_charge(doc, account: nil, date: nil, amount: 0, note: "")
  add(doc, account: account, date: date, amount: amount, note: note, typ: "INTEREST_CHARGE")
end

def add_fees(doc, account: nil, date: nil, amount: 0, security: "", note: "")
  add(doc, account: account, date: date, amount: amount, security: security, note: note, typ: "FEES")
end

def add_fees_refund(doc, account: nil, date: nil, amount: 0, security: "", note: "")
  add(doc, account: account, date: date, amount: amount, security: security, note: note, typ: "FEES_REFUND")
end

def add_taxes(doc, account: nil, date: nil, amount: 0, security: "", note: "")
  add(doc, account: account, date: date, amount: amount, security: security, note: note, typ: "TAXES")
end

def add_tax_refund(doc, account: nil, date: nil, amount: 0, security: "", note: "")
  add(doc, account: account, date: date, amount: amount, security: security, note: note, typ: "TAX_REFUND")
end

def add_dividends(doc, account: nil, date: nil, amount: 0, security: "", shares: 0, tax: 0, note: "")
  add(doc, account: account, date: date, amount: amount, security: security, shares: shares, tax: tax, note: note, typ: "DIVIDENDS")
end

# require 'nokogiri'
# class Nokogiri::XML::Node
#   def path_to( node )
#     self_ancestors = [self].concat(self.ancestors)
#     shared = (self_ancestors & [node].concat(node.ancestors)).first
#     [ "../"*self_ancestors.index(shared),
#       ".", node.path[shared.path.length..-1] ]
#       .join
#       .sub( %r{\A\./|/\.(?=/|\z)}, '' ) # remove superfluous "."
#   end
# end

# def add_transfer(doc, from: nil, to: nil, date: nil, amount: 0)
#   from = doc.css('accounts > account').find{|n| n.css('> name').text() == from }
#   to = doc.css('accounts > account').find{|n| n.css('> name').text() == to }

#   index_account_to = doc.css('accounts > account').index(to)
#   index_account_from = doc.css('accounts > account').index(from)

#   index_transaction_to = to.css('> transactions > transaction').length
#   index_transaction_from = from.css('> transactions > transaction').length

#   from_node = %(
#     <account-transaction>
#       <date>#{date.strftime('%Y-%m-%d')}T00:00</date>
#       <currencyCode>USD</currencyCode>
#       <amount>#{amount * 100}</amount>
#       <crossEntry class="account-transfer">
#         <accountFrom reference="../../../.."/>
#         <transactionFrom reference="../.."/>
#         <accountTo reference="//client/accounts/account[#{index_account_to+1}]" />
#         <transactionTo reference="../accountTo/transactions/account-transaction[#{index_transaction_to+1}]"/>
#       </crossEntry>
#       <shares>0</shares>
#       <type>TRANSFER_OUT</type>
#     </account-transaction>
#   )

#   from.css('> transactions').first.add_child(from_node)

#   to_node = %(
#     <account-transaction>
#       <date reference="//client/accounts/account[#{index_account_from+1}]/transactions/account-transaction[#{index_transaction_from+1}]/date"/>
#       <currencyCode>USD</currencyCode>
#       <amount>#{amount * 100}</amount>
#       <crossEntry class="account-transfer" reference="//client/accounts/account[#{index_account_from+1}]/transactions/account-transaction[#{index_transaction_from+1}]/crossEntry"/>
#       <shares>0</shares>
#       <type>TRANSFER_IN</type>
#     </account-transaction>
#   )

#   to.css('> transactions').first.add_child(to_node)
# end

def add_portfolio_transaction(doc, account: nil, date: nil, amount: 0, tax: 0, fee: 0, shares: 0, security: "", note: "", typ: nil)

  security_index = doc.css('securities > security').index(doc.css('securities > security').find {|n| n.css('> name').text() == security})
  if security_index.nil?
    raise "unable to find security #{security}"
  end

  node = %(
    <portfolio-transaction>
      <date>#{date.strftime('%Y-%m-%d')}T00:00</date>
      <currencyCode>USD</currencyCode>
      <amount>#{(amount * 100).to_i}</amount>
      <security reference="../../../../../../../../../securities/security[#{security_index+1}]"/>
      <crossEntry class="buysell">
        <portfolio reference="../../../.."/>
        <portfolioTransaction reference="../.."/>
        <account reference="../../../../../../../.."/>
        <accountTransaction>
          <date reference="../../../date"/>
          <currencyCode>USD</currencyCode>
          <amount>#{(amount * 100).to_i}</amount>
          <security reference="../../../../../../../../../../../securities/security[#{security_index+1}]"/>
          <crossEntry class="buysell" reference="../.."/>
          <shares>0</shares>
          <type>#{typ}</type>
        </accountTransaction>
      </crossEntry>
      <shares>#{(shares * 1000000).to_i}</shares>
  )

  if !note.blank?
    node += %(
      <note>#{note}</note>
    )
  end

  if tax != 0 || fee != 0
    node += %(
      <units>
    )

    if fee != 0
      node += %(
        <unit type="FEE">
          <amount currency="USD" amount="#{(fee * 100).to_i}"/>
        </unit>
      )
    end

    if tax != 0
      node += %(
        <unit type="TAX">
          <amount currency="USD" amount="#{(tax * 100).to_i}"/>
        </unit>
      )
    end

    node += %(
      </units>
    )
  end

  node += %(
      <type>#{typ}</type>
    </portfolio-transaction>
  )

  portfolio_node = doc.css('portfolio').find{|n| n.css('> name').text() == account }
  node = portfolio_node.css('> transactions').first.add_child(node)
  index = portfolio_node.css('> transactions > portfolio-transaction').length

  node = %(
    <account-transaction reference="../account-transaction/crossEntry/portfolio/transactions/portfolio-transaction[#{index}]/crossEntry/accountTransaction"/>
  )

  account_node = doc.css('account').find{|n| n.css('> name').text() == account }
  account_node.css('> transactions').first.add_child(node)
end

def add_buy(doc, account: nil, date: nil, amount: 0, tax: 0, fee: 0, shares: 0, security: "", note: "")
  add_portfolio_transaction(doc, account: account, date: date, amount: amount, tax: tax, fee: fee, shares: shares, security: security, note: note, typ: "BUY")
end

def add_sell(doc, account: nil, date: nil, amount: 0, tax: 0, fee: 0, shares: 0, security: "", note: "")
  add_portfolio_transaction(doc, account: account, date: date, amount: amount, tax: tax, fee: fee, shares: shares, security: security, note: note, typ: "SELL")
end

# add_deposit(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100)
# add_removal(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100)
# add_interest(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100, tax: 10)
# add_interest_charge(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100)
# add_fees(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100, security: 'PFO2')
# add_fees_refund(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100, security: 'PFO2')
# add_taxes(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100, security: 'PFO2')
# add_tax_refund(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 100, security: 'PFO2')
# add_transfer(doc, from: "Linxea Avenir", to: "Linxea Spirit", date: Date.new(2020,04,15), amount: 100)
# add_buy(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 1000, shares: 123, fee: 1, tax: 2, security: "PFO2")
# add_dividends(doc, account: "Linxea Avenir", date: Date.new(2020,04,15), amount: 10, security: "PFO2", shares: 3, tax: 1, note: "foo")

# doc.css('security').remove

# OpcvmFund.find_each do |fund|
#   doc.css('securities').first.add_child(%(
#     <security>
#       <uuid>#{SecureRandom.uuid}</uuid>
#       <name>#{fund.name.gsub('&', '')}</name>
#       <currencyCode>#{fund.currency.upcase}</currencyCode>
#       <isin>#{fund.isin}</isin>
#       <feed>MANUAL</feed>
#       <prices>
#       </prices>
#       <attributes>
#         <map/>
#       </attributes>
#       <events/>
#       <isRetired>#{fund.closed}</isRetired>
#     </security>
#   ))
# end

# EuroFund.find_each do |fund|
#   doc.css('securities').first.add_child(%(
#     <security>
#       <uuid>#{SecureRandom.uuid}</uuid>
#       <name>#{fund.name.gsub('&', '')}</name>
#       <currencyCode>#{fund.currency.upcase}</currencyCode>
#       <isin></isin>
#       <feed>MANUAL</feed>
#       <prices/>
#       <attributes>
#         <map/>
#       </attributes>
#       <events/>
#       <isRetired>false</isRetired>
#     </security>
#   ))
# end

# ScpiFund.find_each do |fund|
#   doc.css('securities').first.add_child(%(
#     <security>
#       <uuid>#{SecureRandom.uuid}</uuid>
#       <name>#{fund.name.gsub('&', '')}</name>
#       <currencyCode>#{fund.currency.upcase}</currencyCode>
#       <isin></isin>
#       <feed>MANUAL</feed>
#       <prices/>
#       <attributes>
#         <map/>
#       </attributes>
#       <events/>
#       <isRetired>false</isRetired>
#     </security>
#   ))
# end

# Portfolio.where(name: ["Interactive Brokers"]).find_each do |portfolio|

#   doc.css('account').find{|n| n.css('> name').text() == portfolio.name }.css('account-transaction').drop(1).each(&:remove)
#   doc.css('portfolio').find{|n| n.css('> name').text() == portfolio.name }.css('portfolio-transaction').drop(1).each(&:remove)

#   Portfolio.find_by(name: portfolio.name).transactions.order(:done_at).each do |tx|

#     shares = if tx.fund_type == "EuroFund" && tx.shares.nil?
#       tx.amount_original
#     elsif tx.shares.nil?
#       tx.fund.quotation_at(tx.done_at) / tx.amount_original
#     else
#       tx.shares
#     end

#     name = tx.fund.name.gsub('&', '')

#     if tx.category == "Virement" || tx.category == "Arbitrage" || tx.category == "Stock Options"
#       if tx.amount_original >= 0
#         add_deposit(doc, account: portfolio.name, date: tx.done_at, amount: tx.amount_original)
#         add_buy(doc, account: portfolio.name, date: tx.done_at, amount: tx.amount_original, shares: shares, security: name)
#       else
#         add_sell(doc, account: portfolio.name, date: tx.done_at, amount: -tx.amount_original, shares: -shares, security: name)
#         add_removal(doc, account: portfolio.name, date: tx.done_at, amount: -tx.amount_original)
#       end
#     elsif tx.category == "Interets Bancaires" || tx.category == "Dividende"
#       add_dividends(doc, account: portfolio.name, date: tx.done_at, amount: tx.amount_original, security: name)
#       add_buy(doc, account: portfolio.name, date: tx.done_at, amount: tx.amount_original, shares: shares, security: name)
#     elsif tx.category == "Loyer SCPI"
#       add_dividends(doc, account: portfolio.name, date: tx.done_at, amount: tx.amount_original, security: name)
#     elsif tx.category == "Banque:Frais de Souscription" || tx.category == "Banque:Frais de Transfert" || tx.category == "Banque:Frais d'Arbitrage" || tx.category.starts_with?("Impots:") || tx.category.starts_with?("Banque:Commission Change") || tx.category == "Banque:Interet Prêt"
#       add_fees(doc, account: portfolio.name, date: tx.done_at, amount: tx.amount_original, security: name)
#     elsif tx.category == "Banque:Frais de Gestion"
#       add_sell(doc, account: portfolio.name, date: tx.done_at, amount: -tx.amount_original, shares: -shares, security: name)
#       add_fees(doc, account: portfolio.name, date: tx.done_at, amount: -tx.amount_original, security: name)
#     else
#       raise "unknown category #{tx.category}"
#     end

#   end

# end

# OpcvmFund.find_each do |fund|
#   security = doc.css('security').find{|n| n.css('> name').text() == fund.name.gsub('&', '') }
#   if security.nil?
#     raise "unable to find #{fund.name}"
#   end

#   prices = security.css('prices').first
#   prices.css('price').remove

#   fund.quotations.reverse.each do |q|
#     prices.add_child(%(<price t="#{q.date.strftime('%Y-%m-%d')}" v="#{(q.value_original * 10000).to_i}"/>))
#   end
# end

# ScpiFund.find_each do |fund|
#   security = doc.css('security').find{|n| n.css('> name').text() == fund.name.gsub('&', '') }
#   if security.nil?
#     raise "unable to find #{fund.name}"
#   end

#   prices = security.css('prices').first
#   prices.css('price').remove

#   fund.quotations.reverse.each do |q|
#     prices.add_child(%(<price t="#{q.date.strftime('%Y-%m-%d')}" v="#{(q.value_original * 10000).to_i}"/>))
#   end
# end

# OpcvmFund.find_each do |fund|
#   security = doc.css('security').find{|n| n.css('> name').text() == fund.name.gsub('&', '') }
#   if security.nil?
#     raise "unable to find #{fund.name}"
#   end

#   attributes = security.css('attributes').first
#   attributes.css('map').remove

#   if fund.boursorama_id
#     attributes.add_child(%(
#       <map>
#       <entry>
#         <string>3ee65c03-c8f2-4826-9251-ae59f17f9591</string>
#         <bookmark>
#           <label>https://www.boursorama.com/bourse/#{fund.boursorama_type}/cours/#{fund.boursorama_id}/</label>
#           <pattern>https://www.boursorama.com/bourse/#{fund.boursorama_type}/cours/#{fund.boursorama_id}/</pattern>
#         </bookmark>
#       </entry>
#       </map>
#     ))
#   else
#     attributes.add_child(%(
#       <map/>
#     ))
#   end
# end

# with_portfolio_xml("/dropbox/Portfolio Performance/portfolio.xml") do |doc|
#   # OpcvmFund.find_each do |fund|
#   #   security = doc.css('security').find{|n| n.css('> name').text() == fund.name.gsub('&', '') }
#   #   if security.nil?
#   #     raise "unable to find #{fund.name}"
#   #   end

#   #   if fund.boursorama_id
#   #     security.css('feed').remove
#   #     security.add_child(%(
#   #       <feed>GENERIC-JSON</feed>
#   #     ))
#   #   end
#   # end
#   doc.css('security').each do |security|
#     puts security.css('> name').text()
#     if security.css('feed').length != 1
#       raise security
#     end
#   end
# end
