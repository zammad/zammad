class TranslatorKeyAdd < ActiveRecord::Migration
  def up
    Setting.create_if_not_exists(
      title: 'Define translator identifier.',
      name: 'translator_key',
      area: 'i18n::translator_key',
      description: 'Defines the translator identifier for contributions.',
      options: {},
      state: '',
      frontend: false
    )
  end

  def down
  end
end
