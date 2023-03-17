# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ChecksHtmlSanitized
  extend ActiveSupport::Concern

  included do
    before_create :sanitized_html_attributes
    before_update :sanitized_html_attributes
  end

  def sanitized_html_attributes
    html_attributes = self.class.instance_variable_get(:@sanitized_html) || []
    return true if html_attributes.blank?

    options = self.class.instance_variable_get(:@sanitized_html_kwargs).slice(:no_images)

    sanitizer = HtmlSanitizer::Strict.new(**options)

    html_attributes.each do |attr|
      sanitize_single_attribute(attr, sanitizer)
    end
    true
  end

  def sanitizeable?(_attribute, _value)
    true
  end

  private

  def sanitize_single_attribute(attr, sanitizer)
    return if changes[attr].blank?

    value = send(attr)

    return if value.blank?
    return if !sanitizeable?(attr, value)

    send(:"#{attr}=", sanitizer.sanitize(value))
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

serve method to mark HTML attributes that need to get sanitized

class Model < ApplicationModel
  include Sanitized
  sanitized_html :body
end

=end

    def sanitized_html(*attributes, **kwargs)
      @sanitized_html        = attributes
      @sanitized_html_kwargs = kwargs
    end
  end
end
