# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Transaction::ClearbitEnrichment

=begin
  {
    object: 'User',
    type: 'create',
    object_id: 123,
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  },
=end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform

    # return if we run import mode
    return if Setting.get('import_mode')
    return if @item[:object] != 'User'
    return if @item[:type] != 'create'
    return if !Setting.get('clearbit_integration')

    config = Setting.get('clearbit_config')
    return if !config
    return if config['api_key'].blank?

    user = User.lookup(id: @item[:object_id])
    return if !user

    user_enrichment = Enrichment::Clearbit::User.new(user)
    return if !user_enrichment.synced?

    TransactionDispatcher.commit
    true
  end
end
