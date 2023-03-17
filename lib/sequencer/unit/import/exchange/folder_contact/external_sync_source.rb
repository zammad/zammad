# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContact::ExternalSyncSource < Sequencer::Unit::Common::Provider::Named

  def external_sync_source
    'Exchange::FolderContact'
  end
end
