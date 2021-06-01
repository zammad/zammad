# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Exchange
        class AttributeExamples < Sequencer::Unit::Base
          include ::Sequencer::Unit::Exchange::Folders::Mixin::Folder

          uses :ews_folder_ids
          provides :ews_attributes_examples

          def process
            state.provide(:ews_attributes_examples) do
              ::Import::Helper::AttributesExamples.new do |extractor|

                ews_folder_ids.collect do |folder_id|

                  ews_folder.find(folder_id).items.each do |item|

                    attributes = ::Import::Exchange::ItemAttributes.extract(item)
                    extractor.extract(attributes)

                    break if extractor.enough
                  rescue => e
                    Rails.logger.error 'Unable to process Exchange folder item'
                    Rails.logger.debug { item.inspect }
                    Rails.logger.error e
                    nil
                  end
                rescue NoMethodError => e
                  raise if e.message.exclude?('Viewpoint::EWS::')

                  logger.error e
                  logger.error "Skipping folder_id '#{folder_id}' due to unsupported entries."

                end
              end.examples
            end
          end
        end
      end
    end
  end
end
