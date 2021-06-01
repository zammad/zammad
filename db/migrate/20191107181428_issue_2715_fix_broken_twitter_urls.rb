# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'issue_2715_fix_broken_twitter_urls_job' # Rails autoloading expects `issue2715_fix...`

class Issue2715FixBrokenTwitterUrls < ActiveRecord::Migration[5.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Issue2715FixBrokenTwitterUrlsJob.perform_later
  end
end
