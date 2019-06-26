# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_25_013551) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "adhoc_queries", force: :cascade do |t|
    t.jsonb "data"
    t.bigint "node_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["node_id"], name: "index_adhoc_queries_on_node_id"
  end

  create_table "configs", force: :cascade do |t|
    t.string "name"
    t.jsonb "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "nodes", force: :cascade do |t|
    t.bigint "config_id"
    t.string "key"
    t.string "host_identifier"
    t.string "platform_type"
    t.string "os_platform"
    t.string "os_major"
    t.string "os_minor"
    t.string "os_name"
    t.string "os_patch"
    t.string "os_version"
    t.string "sys_computer_name"
    t.string "sys_cpu_brand"
    t.string "sys_cpu_logical_cores"
    t.string "sys_cpu_microcode"
    t.string "sys_cpu_physical_cores"
    t.string "sys_cpu_subtype"
    t.string "sys_cpu_type"
    t.string "sys_hardware_model"
    t.string "sys_hostname"
    t.string "sys_local_hostname"
    t.string "sys_physical_memory"
    t.string "sys_uuid"
    t.string "osqi_build_distro"
    t.string "osqi_build_platform"
    t.string "osqi_config_hash"
    t.string "osqi_config_valid"
    t.string "osqi_extensions"
    t.string "osqi_instance_id"
    t.string "osqi_pid"
    t.string "osqi_start_time"
    t.string "osqi_uuid"
    t.string "osqi_version"
    t.index ["config_id"], name: "index_nodes_on_config_id"
  end

  add_foreign_key "adhoc_queries", "nodes"
  add_foreign_key "nodes", "configs"
end
