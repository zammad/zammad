# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue1219ZhtwLocaleTypo < ActiveRecord::Migration[5.1]
  CURRENT_VERSION    = Gem::Version.new(Version.get)
  APPLICABLE_VERSION = Gem::Version.new('2.5.0')

  def up
    return if !Setting.exists?(name: 'system_init_done')
    return if CURRENT_VERSION < APPLICABLE_VERSION

    if Locale.exists?(locale: 'zh-tw')
      Locale.find_by(locale: 'zj-tw')&.destroy
    else
      Locale.find_by(locale: 'zj-tw')&.update(locale: 'zh-tw')
    end

    Translation.where(locale: 'zj-tw')&.update_all(locale: 'zh-tw') # rubocop:disable Rails/SkipsModelValidations
    User.where('preferences LIKE ?', "%\nlocale: zj-tw\n%").each do |u|
      u.preferences[:locale] = 'zh-tw'
      u.save
    end
  end

  def down
    return if !Setting.exists?(name: 'system_init_done')
    return if CURRENT_VERSION >= APPLICABLE_VERSION

    if Locale.exists?(locale: 'zj-tw')
      Locale.find_by(locale: 'zh-tw')&.destroy
    else
      Locale.find_by(locale: 'zh-tw')&.update(locale: 'zj-tw')
    end

    Translation.where(locale: 'zh-tw')&.update_all(locale: 'zj-tw') # rubocop:disable Rails/SkipsModelValidations
    User.where('preferences LIKE ?', "%\nlocale: zh-tw\n%").each do |u|
      u.preferences[:locale] = 'zj-tw'
      u.save
    end
  end
end
