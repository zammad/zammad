# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Ldap
        module User
          class NormalizeEntry < Sequencer::Unit::Base
            uses :resource
            provides :resource

            def process

              state.provide(:resource) do
                empty = ActiveSupport::HashWithIndifferentAccess.new
                resource.each_with_object(empty) do |(key, values), normalized|
                  normalized[key] = values.first
                end
              end
            end
          end
        end
      end
    end
  end
end
