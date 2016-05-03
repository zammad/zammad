class UpdateTransaction < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_or_update(
      title: 'Define sync transaction backend.',
      name: '0100_trigger',
      area: 'Transaction::Backend::Sync',
      description: 'Define the transaction backend to execute triggers.',
      options: {},
      state: 'Transaction::Trigger',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '0100_notification',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend to send agent notifications.',
      options: {},
      state: 'Transaction::Notification',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '1000_signature_detection',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend to detect customers signature in email.',
      options: {},
      state: 'Transaction::SignatureDetection',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '6000_slack_webhook',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend which posts messages to (http://www.slack.com).',
      options: {},
      state: 'Transaction::Slack',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '9000_clearbit_enrichment',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend which will enrich customer and organization informations from (http://www.clearbit.com).',
      options: {},
      state: 'Transaction::ClearbitEnrichment',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Define transaction backend.',
      name: '9100_cti_caller_id_detection',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend which detects caller ids in objects and store them for cti lookups.',
      options: {},
      state: 'Transaction::CtiCallerIdDetection',
      frontend: false
    )

  end
end
