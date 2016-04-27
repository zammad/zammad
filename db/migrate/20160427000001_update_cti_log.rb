class UpdateCtiLog < ActiveRecord::Migration
  def up
    add_column  :cti_logs, :start,       :timestamp,  null: true
    add_column  :cti_logs, :end,         :timestamp,  null: true
    add_column  :cti_logs, :done,        :boolean,    null: false, default: true
  end
end
