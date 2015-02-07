# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150207173634) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "fund_cotations", force: :cascade do |t|
    t.integer  "fund_id"
    t.decimal  "value",      precision: 10, scale: 2
    t.date     "date"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "funds", force: :cascade do |t|
    t.string   "isin"
    t.string   "name"
    t.string   "boursorama_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "url"
  end

  create_table "portfolio_transactions", force: :cascade do |t|
    t.integer  "fund_id"
    t.decimal  "shares",       precision: 10, scale: 5
    t.integer  "portfolio_id"
    t.date     "done_at"
    t.decimal  "amount",       precision: 10, scale: 5
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "portfolios", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "fund_cotations", "funds"
  add_foreign_key "portfolio_transactions", "funds"
  add_foreign_key "portfolio_transactions", "portfolios"
end
