# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow
  include ::Mixin::HasBackends

  def self.perform_mapping(perform_result, result, relation_fields:)
    initialize_fields(perform_result, result)

    backends.each do |backend|
      backend.perform(
        perform_result:  perform_result,
        result:          result,
        relation_fields: relation_fields
      )
    end
  end

  # We initialize the fields with the visibility result, because this is the identifier for the fields which are
  # relevant for the current form. Also some other mapping modules need some information form the visibility.
  def self.initialize_fields(perform_result, result)
    perform_result[:visibility].each do |name, visibility|
      result[name] ||= {}

      result[name][:show] = visibility != 'remove'
      result[name][:hidden] = false

      # Then the element is only hidden, we want to preverse the an existing value.
      if visibility == 'hide'
        result[name][:hidden] = true
      end
    end
  end
end
