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

ActiveRecord::Schema[8.1].define(version: 2026_10_12_060006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "menu_categories", force: :cascade do |t|
    t.string "name_ko", null: false
    t.string "name_en"
    t.string "name_vi"
    t.string "name_ja"
    t.integer "position", default: 0, null: false
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_menu_categories_on_position"
  end

  create_table "menu_items", force: :cascade do |t|
    t.bigint "menu_category_id", null: false
    t.string "name_ko", null: false
    t.string "name_en"
    t.string "name_vi"
    t.string "name_ja"
    t.integer "price", default: 0, null: false
    t.boolean "price_from", default: false, null: false
    t.text "description_ko"
    t.text "description_en"
    t.text "description_vi"
    t.text "description_ja"
    t.integer "position", default: 0, null: false
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_category_id", "position"], name: "index_menu_items_on_menu_category_id_and_position"
    t.index ["menu_category_id"], name: "index_menu_items_on_menu_category_id"
  end

  create_table "owner_profiles", force: :cascade do |t|
    t.text "name_ko"
    t.text "name_en"
    t.text "name_vi"
    t.text "name_ja"
    t.text "headline_ko"
    t.text "headline_en"
    t.text "headline_vi"
    t.text "headline_ja"
    t.text "greeting_ko"
    t.text "greeting_en"
    t.text "greeting_vi"
    t.text "greeting_ja"
    t.text "career_ko"
    t.text "career_en"
    t.text "career_vi"
    t.text "career_ja"
    t.integer "years_of_experience", default: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "title_ko", null: false
    t.string "title_en"
    t.string "title_vi"
    t.string "title_ja"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published", "published_at"], name: "index_posts_on_published_and_published_at"
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "phone"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.text "tagline_ko"
    t.text "tagline_en"
    t.text "tagline_vi"
    t.text "tagline_ja"
    t.text "address_ko"
    t.text "address_en"
    t.text "address_vi"
    t.text "address_ja"
    t.text "hours_ko"
    t.text "hours_en"
    t.text "hours_vi"
    t.text "hours_ja"
    t.text "closed_days_ko"
    t.text "closed_days_en"
    t.text "closed_days_vi"
    t.text "closed_days_ja"
    t.text "parking_ko"
    t.text "parking_en"
    t.text "parking_vi"
    t.text "parking_ja"
    t.text "entrance_ko"
    t.text "entrance_en"
    t.text "entrance_vi"
    t.text "entrance_ja"
    t.text "business_info_ko"
    t.text "business_info_en"
    t.text "business_info_vi"
    t.text "business_info_ja"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "menu_items", "menu_categories"
end
