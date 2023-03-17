# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Exchange::FolderContacts::DryRunPayload < Sequencer::Unit::Import::Common::ImportJob::Payload::ToAttribute

  provides :ews_config, :ews_folder_ids
end
