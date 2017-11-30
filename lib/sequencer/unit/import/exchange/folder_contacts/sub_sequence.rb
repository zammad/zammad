class Sequencer
  class Unit
    module Import
      module Exchange
        module FolderContacts
          class SubSequence < Sequencer::Unit::Base
            include ::Sequencer::Unit::Exchange::Folders::Mixin::Folder
            include ::Sequencer::Unit::Import::Common::SubSequence::Mixin::ImportJob

            uses :ews_folder_ids

            def process
              return if ews_folder_ids.blank?

              ews_folder_ids.each do |folder_id|
                folder       = ews_folder.find(folder_id)
                display_path = ews_folder.display_path(folder)

                sequence_resources(folder.items) do |parameters|

                  item = parameters[:resource]

                  logger.debug("Extracting attributes from Exchange item: #{item.get_all_properties!.inspect}")

                  parameters.merge(
                    resource:        ::Import::Exchange::ItemAttributes.extract(item),
                    ews_folder_name: display_path,
                  )
                end
              end
            end

            private

            def sequence
              'Import::Exchange::FolderContact'
            end
          end
        end
      end
    end
  end
end
