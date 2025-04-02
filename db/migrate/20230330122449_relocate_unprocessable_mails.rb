# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class RelocateUnprocessableMails < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    relocate_files('unprocessable_mail')
    relocate_files('oversized_mail')
  end

  def relocate_files(type)
    old_dir = Rails.root.join('tmp', type)
    return if !old_dir.exist? || old_dir.children.empty?

    new_dir = Rails.root.join('var/spool', type)
    begin
      # In case of readonly file systems (like in k8s), skip this migration.
      FileUtils.mkdir_p(new_dir)
    rescue
      return
    end

    FileUtils.cp_r(old_dir.children, new_dir)
    FileUtils.rm_r(old_dir)
  end
end
