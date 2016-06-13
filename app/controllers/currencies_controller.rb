# frozen_string_literal: true
class CurrenciesController < ApplicationController
  def create
    ActiveRecord::Base.transaction do
      currency = Currency.new(url: create_params[:url])
      currency.refresh_data
      currency.refresh_quotation_history
    end

    render nothing: true
  end

  def create_params
    params.permit(:url)
  end
end
