require 'sequencer/mixin/exchange/folder'

class Sequencer
  class Unit
    module Import
      module Exchange
        class AttributeExamples < Sequencer::Unit::Base
          include ::Sequencer::Mixin::Exchange::Folder

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
                end
              end.examples
            end
          end
        end
      end
    end
  end
end
