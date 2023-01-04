# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TextModule < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include CanCsvImport

  validates :name,    presence: true
  validates :content, presence: true

  before_create  :validate_content
  before_update  :validate_content

  validates :note, length: { maximum: 250 }
  sanitized_html :content, :note

  csv_delete_possible true

  has_and_belongs_to_many :groups, after_add: :cache_update, after_remove: :cache_update, class_name: 'Group'

  association_attributes_ignored :user

=begin

import text modules from i18n/text_modules/*.yml if no text modules exist yet.

  TextModule.load('de-de') # e. g. 'en-us' or 'de-de'

=end

  def self.load(locale)
    raise __("The required parameter 'locale' is missing.") if locale.blank?

    return if !TextModule.count.zero?

    locale = locale.split(',').first.downcase # in case of accept_language header is given

    # First check the full locale, e.g. 'de-de'.
    filename = Rails.root.join("i18n/text_modules/#{locale}.yml")
    if !File.exist?(filename)
      # Fall back to the more generic language if needed, e.g. 'de'.
      locale = locale.split('-').first
      filename = Rails.root.join("i18n/text_modules/#{locale}.yml")
    end

    if !File.exist?(filename)
      # No text modules available for current locale data.
      return
    end

    file_content = File.read(filename)
    result = Psych.load(file_content)

    raise "Can't load text modules from #{filename}" if result.empty?

    ActiveRecord::Base.transaction do
      result.each do |text_module|
        text_module[:updated_by_id] = 1
        text_module[:created_by_id] = 1
        TextModule.create(text_module.symbolize_keys!)
      end
    end
    true
  end

  private

  def validate_content
    return true if content.blank?
    return true if content.match?(%r{<.+?>})

    content.gsub!(%r{(\r\n|\n\r|\r)}, "\n")
    self.content = content.text2html
    true
  end

end
