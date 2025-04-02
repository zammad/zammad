# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateFailedEmails < ActiveRecord::Migration[7.0]
  OLD_FAILED_EMAIL_DIRECTORY = Rails.root.join('var/spool/unprocessable_mail')

  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :failed_emails do |t|
      t.binary  :data,         null: false
      t.integer :retries,      null: false, default: 1
      t.text    :parsing_error

      t.timestamps limit: 3, null: false
    end

    return if !Dir.exist?(OLD_FAILED_EMAIL_DIRECTORY)

    import_emails
    remove_old_unprocessable_emails
  end

  def down
    drop_table :failed_emails
  end

  private

  def remove_old_unprocessable_emails
    FileUtils.rm_rf OLD_FAILED_EMAIL_DIRECTORY
  rescue # handle read-only file systems gracefully
    nil
  end

  def import_emails
    Dir.each_child(OLD_FAILED_EMAIL_DIRECTORY) do |filename|
      next if !filename.ends_with? '.eml'

      import_single_email(filename)
    end
  end

  def import_single_email(filename)
    path = OLD_FAILED_EMAIL_DIRECTORY.join(filename)
    data = File.binread(path)

    FailedEmail.create(data:)
  end
end
