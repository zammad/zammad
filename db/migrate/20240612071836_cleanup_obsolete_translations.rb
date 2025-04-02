# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CleanupObsoleteTranslations < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # https://github.com/zammad/zammad/issues/5189
    # When the Weblate toolchain was introduced to Zammad, old Translation records were
    #   not automatically cleaned up, causing lots of customized translations to be
    #   shown in the translation management screen, even though they came from the codebase.
    # This method locates and deletes all Translations which are present in many languages
    #   and not changed by the user.
    old_scope = 'target_initial = target AND is_synchronized_from_codebase = false'
    sources = Translation.where(old_scope).having('COUNT(*) >= 20').group(:source).pluck(:source)
    Translation.where(old_scope).where(source: sources).delete_all
  end
end
