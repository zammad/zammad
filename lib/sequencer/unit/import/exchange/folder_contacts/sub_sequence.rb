require 'sequencer/mixin/exchange/folder'
require 'sequencer/mixin/import_job/resource_loop'

class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class SubSequence < Sequencer::Unit::Base
            include ::Sequencer::Mixin::Exchange::Folder
            include ::Sequencer::Mixin::ImportJob::ResourceLoop

            uses :ews_folder_ids, :import_job

            def process

              ews_folder_ids.each do |folder_id|
                folder       = ews_folder.find(folder_id)
                display_path = ews_folder.display_path(folder)

                resource_sequence('Import::Exchange::FolderContact', folder.items) do |item|

                  logger.debug("Extracting attributes from Exchange item: #{item.get_all_properties!.inspect}")

                  {
                    resource:        ::Import::Exchange::ItemAttributes.extract(item),
                    ews_folder_name: display_path,
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
