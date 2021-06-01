# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CustomHtmlEmailCssFont < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'HTML Email CSS Font',
      name:        'html_email_css_font',
      area:        'Core',
      description: 'Defines the CSS font information for HTML Emails.',
      options:     {},
      state:       "font-family:'Helvetica Neue', Helvetica, Arial, Geneva, sans-serif; font-size: 12px;",
      preferences: {
        permission: ['admin'],
      },
      frontend:    false
    )

  end
end
