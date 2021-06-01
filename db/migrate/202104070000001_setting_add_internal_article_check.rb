# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingAddInternalArticleCheck < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Define postmaster filter.',
      name:        '5500_postmaster_internal_article_check',
      area:        'Postmaster::PreFilter',
      description: 'Defines the postmaster filter which set the article internal if a forwarded, replied or sent email also exists with the article internal received.',
      options:     {},
      state:       'Channel::Filter::InternalArticleCheck',
      frontend:    false
    )
  end
end
