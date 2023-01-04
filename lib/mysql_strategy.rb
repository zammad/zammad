# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'fileutils'
require 'digest'

class MysqlStrategy
  def self.db?
    ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'mysql2'
  end

  def self.db_checksum
    @@db_checksum ||= begin # rubocop:disable Style/ClassVars
      files = Dir[ Rails.root.join('db/**/*') ].reject { |f| File.directory?(f) }
      content = files.map { |f| File.read(f) }.join
      Digest::MD5.hexdigest(content).to_s
    end
  end

  def self.basepath
    Rails.root.join("tmp/mysql_reset/#{db_checksum}/")
  end

  def self.backup_file
    "#{basepath}db.sql"
  end

  def self.backup_exists?
    File.exist?(backup_file)
  end

  def self.username
    ActiveRecord::Base.connection.instance_values['config'][:username]
  end

  def self.password
    ActiveRecord::Base.connection.instance_values['config'][:password]
  end

  def self.host
    ActiveRecord::Base.connection.instance_values['config'][:host] || '127.0.0.1'
  end

  def self.database
    ActiveRecord::Base.connection.instance_values['config'][:database]
  end

  def self.mysql_arguments
    args = " -u#{username} -h#{host}"
    args += " -p#{password}" if password.present?  # allow for passwordless access on dev systems
    args + " #{database}"
  end

  def self.rollback
    system("mysql #{mysql_arguments} < #{backup_file}", exception: true)
    Rake::Task['zammad:db:rebuild'].reenable
    Rake::Task['zammad:db:rebuild'].invoke
  end

  def self.backup
    Rake::Task['zammad:db:reset'].reenable
    Rake::Task['zammad:db:reset'].invoke
    system("mysqldump #{mysql_arguments} > #{backup_file}", exception: true)
  end

  def self.reset
    FileUtils.mkdir_p Rails.root.join(basepath)
    if backup_exists?
      rollback
    else
      backup
    end
  end
end
