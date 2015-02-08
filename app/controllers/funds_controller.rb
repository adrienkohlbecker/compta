class FundsController < ApplicationController

  def create

    ActiveRecord::Base.transaction do
      fund = Fund.new(url: create_params[:url])
      fund.refresh_data
      fund.refresh_quotation_history
    end

    render nothing: true

  end

  def create_params
    params.permit(:url)
  end

end
