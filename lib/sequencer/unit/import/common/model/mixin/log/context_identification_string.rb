# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# When building generic Sequencer Units in various contexts it's not possible know
# which model, resource, mapped or instance is present at the moment or even used
# in the Sequence at all.
# But at the same time it's desirable to write an expressive log line that eases
# the Debugging Experience and makes it possible to identify the processed data context.
# This Mixin provides the method `context_identification_string` to build a String
# that includes all available information ready to write to the log.
class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module Log
              module ContextIdentificationString

                def self.included(base)
                  base.optional :model_class, :resource, :mapped, :instance
                end

                # Call this method in your Unit. It contains all the available context information.
                #
                # @example
                #  context_identification_string
                #  # => 'for Model 'User' possible identified by 'id, email, login' from resource identified by '{id: 1337}...
                #
                def context_identification_string
                  "#{model_identifier_part}#{resource_identifier_part}#{mapped_identifier_part}#{instance_identifier_part}"
                end

                def possible_identifier_attributes
                  @possible_identifier_attributes ||= begin
                    lookup_keys = model_class.present? ? model_class.lookup_keys : []
                    # add default lookup attributes to the lookup keys of a possibly present Model
                    lookup_keys | %i[id name login email number]
                  end
                end

                def model_identifier_part
                  return if model_class.blank?

                  " for Model '#{model_class}' possibly identified by '#{possible_identifier_attributes.join(', ')}'"
                end

                def resource_identifier_part
                  return if resource.blank?

                  return ' from unidentifiable resource' if resource_identifier_part_data.blank?

                  " from resource identified by '#{resource_identifier_part_data.inspect}'"
                end

                def mapped_identifier_part
                  return if mapped.blank?

                  mapped_identifier_part_data = mapped.slice(*possible_identifier_attributes)

                  return ' without mapped identifiers' if mapped_identifier_part_data.blank?

                  " with mapped identifiers '#{mapped_identifier_part_data.inspect}'"
                end

                def instance_identifier_part
                  return if instance.blank?

                  instance_identifier_part_data = {}
                  possible_identifier_attributes.each do |key|
                    next if !instance.respond_to?(key)

                    instance_identifier_part_data[key] = instance.public_send(key)
                  end

                  return ' with unidentifiable instance' if instance_identifier_part_data.blank?

                  " with instance identified by '#{instance_identifier_part_data.inspect}'"
                end

                private

                def resource_identifier_part_data
                  @resource_identifier_part_data ||= begin
                    if resource.respond_to?(:[])
                      resource_identifier_part_data_from_hash
                    else
                      resource_identifier_part_data_from_methods
                    end
                  end
                end

                def resource_identifier_part_data_from_hash
                  possible_identifier_attributes.each_with_object({}) do |key, result|
                    next if resource[key].blank?

                    result[key] = resource[key]
                  end
                end

                def resource_identifier_part_data_from_methods
                  possible_identifier_attributes.each_with_object({}) do |key, result|
                    next if !resource.respond_to?(key)

                    result[key] = resource.public_send(key)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
