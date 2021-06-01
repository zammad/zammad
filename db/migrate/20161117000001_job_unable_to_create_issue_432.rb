# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class JobUnableToCreateIssue432 < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ActiveRecord::Migration.change_table :jobs do |t|
      t.change :timeplan, :string, limit: 2500
      t.change :condition, :text, limit: 500.kilobytes + 1
      t.change :perform, :text, limit: 500.kilobytes + 1
    end

    ActiveRecord::Migration.change_table :triggers do |t|
      t.change :condition, :text, limit: 500.kilobytes + 1
      t.change :perform, :text, limit: 500.kilobytes + 1
    end

    ActiveRecord::Migration.change_table :overviews do |t|
      t.change :condition, :text, limit: 500.kilobytes + 1
    end

    ActiveRecord::Migration.change_table :report_profiles do |t|
      t.change :condition, :text, limit: 500.kilobytes + 1
    end
    ActiveRecord::Migration.change_table :slas do |t|
      t.change :condition, :text, limit: 500.kilobytes + 1
    end

    ActiveRecord::Migration.change_table :macros do |t|
      t.change :perform, :text, limit: 500.kilobytes + 1
    end

    ActiveRecord::Migration.change_table :postmaster_filters do |t|
      t.change :match, :text, limit: 500.kilobytes + 1
      t.change :perform, :text, limit: 500.kilobytes + 1
    end

    ActiveRecord::Migration.change_table :stats_stores do |t|
      t.change :data, :string, limit: 5000
    end

    Cache.clear

  end
end
