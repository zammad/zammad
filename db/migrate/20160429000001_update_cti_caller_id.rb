class UpdateCtiCallerId < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Define transaction backend.',
      name: '9100_cti_caller_id_detection',
      area: 'Transaction::Backend',
      description: 'Define the transaction backend which detects caller ids in objects and store them for cti lookups.',
      options: {},
      state: 'Transaction::CtiCallerIdDetection',
      frontend: false
    )
    add_column :cti_logs, :preferences, :text, limit: 500.kilobytes + 1, null: true
  end
end
