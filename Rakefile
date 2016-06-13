# frozen_string_literal: true
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'net/http'

Rails.application.load_tasks

task daily: :environment do
  puts 'Refreshing quotations...'
  refresh_quotations!
  puts 'Exporting excel files...'
  excel_export!('/dropbox')
end
