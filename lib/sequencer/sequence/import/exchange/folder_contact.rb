class Sequencer
  class Sequence
    module Import
      module Exchange
        class FolderContact < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Exchange::FolderContact::RemoteId',
              'Import::Exchange::FolderContact::Mapping',
              'Import::Common::Model::Skip::Blank::Mapped',
              'Import::Exchange::FolderContact::StaticAttributes',
              'Import::Common::Model::ExternalSync::Lookup',
              'Import::Common::Model::Associations::Extract',
              'Import::Common::User::Attributes::Downcase',
              'Import::Common::User::Email::CheckValidity',
              'Import::Common::Model::Attributes::AddByIds',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Associations::Assign',
              'Import::Common::Model::Save',
              'Import::Common::Model::ExternalSync::Create',
              'Import::Exchange::FolderContact::HttpLog',
              'Import::Exchange::FolderContact::Statistics::Diff',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
            ]
          end
        end
      end
    end
  end
end
