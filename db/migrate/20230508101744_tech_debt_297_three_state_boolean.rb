# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TechDebt297ThreeStateBoolean < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    users_vip
    roles_default_at_signup
    import_jobs_dry_run
    tokens_persistent

    change_column_default :ticket_article_types, :communication, false
    change_column_default :settings, :frontend, false

    Rails.cache.clear
  end

  private

  def users_vip
    User.where(vip: nil).in_batches.each_record do |user|
      user.update_columns(vip: false) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column_null :users, :vip, false, false
  end

  def roles_default_at_signup
    Role.where(default_at_signup: nil).each do |role|
      role.update_columns(default_at_signup: false) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column_null :roles, :default_at_signup, false, false
  end

  def import_jobs_dry_run
    ImportJob.where(dry_run: nil).each do |import_job|
      import_job.update_columns(dry_run: false) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column_null :import_jobs, :dry_run, false, false
  end

  def tokens_persistent
    Token.where(persistent: nil).each do |token|
      token.update_columns(persistent: false) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column_default :tokens, :persistent, false
    change_column_null    :tokens, :persistent, false, false
  end
end
