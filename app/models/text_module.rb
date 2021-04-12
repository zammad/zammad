# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TextModule < ApplicationModel
  include ChecksClientNotification
  include ChecksHtmlSanitized
  include CanCsvImport

  validates :name,    presence: true
  validates :content, presence: true

  before_create  :validate_content
  before_update  :validate_content

  sanitized_html :content, :note

  csv_delete_possible true

  has_and_belongs_to_many :groups, after_add: :cache_update, after_remove: :cache_update, class_name: 'Group'

  association_attributes_ignored :user

=begin

load text modules from online

  TextModule.load('de-de', overwrite_existing_item) # e. g. 'en-us' or 'de-de'

=end

  def self.load(locale, overwrite_existing_item = false)
    raise 'Got no locale' if locale.blank?

    locale = locale.split(',').first.downcase # in case of accept_language header is given
    url = "https://i18n.zammad.com/api/v1/text_modules/#{locale}"

    result = UserAgent.get(
      url,
      {},
      {
        json: true,
      }
    )

    raise "Can't load text modules from #{url}" if !result
    raise "Can't load text modules from #{url}: #{result.error}" if !result.success?

    ActiveRecord::Base.transaction do
      result.data.each do |text_module|
        exists = TextModule.find_by(foreign_id: text_module['foreign_id'])
        if exists
          next if !overwrite_existing_item

          exists.update!(text_module.symbolize_keys!)
        else
          text_module[:updated_by_id] = 1
          text_module[:created_by_id] = 1
          TextModule.create(text_module.symbolize_keys!)
        end
      end
    end
    true
  end

=begin

push text_modules to online

  TextModule.push(locale)

=end

  def self.push(locale)

    # only push changed text_modules
    text_modules         = TextModule.all #where(locale: locale)
    text_modules_to_push = []
    text_modules.each do |text_module|
      next if !text_module.active

      text_modules_to_push.push text_module
    end

    return true if text_modules_to_push.blank?

    url = 'https://i18n.zammad.com/api/v1/text_modules/thanks_for_your_support'

    translator_key = Setting.get('translator_key')

    result = UserAgent.post(
      url,
      {
        locale:         locale,
        text_modules:   text_modules_to_push,
        fqdn:           Setting.get('fqdn'),
        translator_key: translator_key,
      },
      {
        json:         true,
        open_timeout: 6,
        read_timeout: 16,
      }
    )
    raise "Can't push text_modules to #{url}: #{result.error}" if !result.success?

    # set new translator_key if given
    if result.data['translator_key']
      Setting.set('translator_key', result.data['translator_key'])
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
