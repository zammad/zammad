# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::Backend
  def initialize(result_object:, field:, perform_config:)
    @result_object  = result_object
    @field          = field
    @perform_config = perform_config
  end

  def field
    @field.sub(%r{.*\.}, '')
  end

  def set_rerun
    @result_object.rerun = true
  end

  def result(backend, field, value = nil)
    @result_object.run_backend_value(backend, field, value)
  end

  def saved_value

    # make sure we have a saved object
    return if @result_object.attributes.saved_only.blank?

    # we only want to have the saved value in the restrictions
    # if no changes happend to the form. If the users does changes
    # to the form then also the saved value should get removed
    return if @result_object.attributes.selected.changed?

    # attribute can be blank e.g. in custom development
    # or if attribute is only available in the frontend but not
    # in the backend
    return if attribute.blank?

    @result_object.attributes.saved_attribute_value(attribute).to_s
  end

  def attribute
    @attribute ||= @result_object.attributes.object_elements_hash[field]
  end
end
