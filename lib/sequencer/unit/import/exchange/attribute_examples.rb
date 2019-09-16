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

                  ews_folder.find(folder_id).items.each do |resource|
                    attributes = ::Import::Exchange::ItemAttributes.extract(resource)
                    extractor.extract(attributes)
                    break if extractor.enough
                  end
                rescue NoMethodError => e
                  raise if !e.message.match?(/Viewpoint::EWS::/)

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
