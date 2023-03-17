# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizerProcessingTimeout < ActiveRecord::Migration[6.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'HTML Sanitizer Processing Timeout',
      name:        'html_sanitizer_processing_timeout',
      area:        'Core',
      description: 'Defines processing timeout for the html sanitizer.',
      options:     {},
      state:       20,
      preferences: {},
      frontend:    false
    )
  end
end
