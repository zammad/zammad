# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class Attachments < Sequencer::Unit::Import::Zendesk::SubSequence::SubObject

              def process
                # check if we need to import the attachments
                return if skip?

                # if so call the original .process from SubObject class
                super
              end

              private

              # for better readability
              alias remote_attachments resource_collection

              # for better readability
              def local_attachments
                instance.attachments
              end

              def skip?
                ensure_common_ground
                attachments_equal?
              end

              def ensure_common_ground
                return if common_ground?

                local_attachments.each(&:delete)
              end

              def common_ground?
                return false if remote_attachments.blank?

                attachments_equal?
              end

              def attachments_equal?
                remote_attachments.count == local_attachments.count
              end

              def sequence_name
                "Import::Zendesk::Ticket::Comment::#{resource_klass}"
              end

              def resource_iteration_method
                :each
              end
            end
          end
        end
      end
    end
  end
end
