# frozen_string_literal: true

require 'pry'
require_relative 'files.rb'

ActiveRecord::Base.logger = Logger.new(STDOUT)

Pry.start
