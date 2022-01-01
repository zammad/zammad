# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Exchange
        class FolderContacts < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Exchange::FolderContacts::DryRunPayload',
              'Exchange::Connection',
              'Import::Exchange::FolderContacts::FolderIds',
              'Import::Exchange::FolderContacts::Total',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
              'Import::Exchange::FolderContacts::SubSequence',
            ]
          end
        end
      end
    end
  end
end
