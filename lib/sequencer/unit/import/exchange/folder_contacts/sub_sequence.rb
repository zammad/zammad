# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
                folder = ews_folder.find(folder_id)
                paginated_item_sequence(folder)
              end
            end

            private

            def paginated_item_sequence(folder)

              total    = folder.total_count
              per_page = 1000
              pages    = (total.to_f / per_page).ceil

              display_path = ews_folder.display_path(folder)
              (1..pages).each do |page|

                offset = (page - 1) * per_page

                opts = {
                  indexed_page_item_view: {
                    max_entries_returned: per_page,
                    offset:               offset,
                    base_point:           'Beginning'
                  }
                }

                logger.debug { "Fetching and processing #{per_page} items (page: #{page}, offset: #{offset}) from Exchange folder '#{display_path}' (total: #{total})" }

                process_folders(folder, display_path, opts)
              end
            end

            def process_folders(folder, display_path, opts)
              folder.items(opts).each do |item|

                sequence_resource do |parameters|

                  logger.debug { "Extracting attributes from Exchange item: #{item.get_all_properties!.inspect}" }

                  parameters.merge(
                    resource:        ::Import::Exchange::ItemAttributes.extract(item),
                    ews_folder_name: display_path,
                  )
                rescue => e
                  Rails.logger.error 'Unable to process Exchange folder item'
                  Rails.logger.debug { item.inspect }
                  Rails.logger.error e
                  nil
                end
              end
            end

            def sequence
              'Import::Exchange::FolderContact'
            end
          end
        end
      end
    end
  end
end
