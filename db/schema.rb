# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_11_09_092632) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "statement_requests", force: :cascade do |t|
    t.string "public_token", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_statement_requests_on_expires_at"
    t.index ["public_token"], name: "index_statement_requests_on_public_token", unique: true
  end

  create_table "statements", force: :cascade do |t|
    t.string "account_number"
    t.string "phone_number"
    t.string "email"
    t.string "branch_code"
    t.string "status", default: "pending"
    t.string "file_path"
    t.date "from_date"
    t.date "to_date"
    t.string "core_reference_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "statement_request_id"
    t.index ["statement_request_id"], name: "index_statements_on_statement_request_id"
  end

  create_table "verifications", force: :cascade do |t|
    t.string "otp_code"
    t.datetime "otp_sent_at"
    t.integer "attempts", default: 0
    t.integer "otp_resend_count", default: 0
    t.boolean "verified"
    t.bigint "statement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "statement_request_id"
    t.index ["statement_id"], name: "index_verifications_on_statement_id"
    t.index ["statement_request_id"], name: "index_verifications_on_statement_request_id"
  end

  add_foreign_key "statements", "statement_requests"
  add_foreign_key "verifications", "statement_requests"
  add_foreign_key "verifications", "statements"
end
