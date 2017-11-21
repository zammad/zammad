# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ChecksHtmlSanitized
  extend ActiveSupport::Concern

  included do
    before_create :sanitized_html_attributes
    before_update :sanitized_html_attributes
  end

  def sanitized_html_attributes
    html_attributes = self.class.instance_variable_get(:@sanitized_html) || []
    return true if html_attributes.blank?

    html_attributes.each do |attribute|
      value = send(attribute)

      next if value.blank?
      next if !sanitizeable?(attribute, value)

      send("#{attribute}=".to_sym, HtmlSanitizer.strict(value))
    end
    true
  end

  def sanitizeable?(_attribute, _value)
    true
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

    def sanitized_html(*attributes)
      @sanitized_html = attributes
    end
  end
end
