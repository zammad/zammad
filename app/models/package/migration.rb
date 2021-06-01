# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Package::Migration < ApplicationModel

  def self.linked
    szpm_files = []
    Dir.chdir(root) do
      szpm_files = Dir['*.szpm']
    end

    szpm_files.each do |szpm_file|
      package = szpm_file.sub('.szpm', '')
      migrate(package)
    end
  end

  def self.migrate(package, direction = 'normal')
    location = "#{root}/db/addon/#{package.underscore}"

    return true if !File.exist?(location)

    # get existing migrations
    migrations_existing = []
    Dir.foreach(location) do |entry|
      next if entry == '.'
      next if entry == '..'

      migrations_existing.push entry
    end

    # up
    migrations_existing = migrations_existing.sort

    # down
    if direction == 'reverse'
      migrations_existing = migrations_existing.reverse
    end

    migrations_existing.each do |migration|
      next if !migration.end_with?('.rb')

      version = nil
      name    = nil
      if migration =~ %r{^(.+?)_(.*)\.rb$}
        version = $1
        name    = $2
      end
      if !version || !name
        raise "Invalid package migration '#{migration}'"
      end

      # down
      done = Package::Migration.find_by(name: package.underscore, version: version)
      if direction == 'reverse'
        next if !done

        logger.info "NOTICE: down package migration '#{migration}'"
        load "#{location}/#{migration}"
        classname = name.camelcase
        classname.constantize.down
        record = Package::Migration.find_by(name: package.underscore, version: version)
        record&.destroy

        # up
      else
        next if done

        logger.info "NOTICE: up package migration '#{migration}'"
        load "#{location}/#{migration}"
        classname = name.camelcase
        classname.constantize.up
        Package::Migration.create(name: package.underscore, version: version)
      end
    end
  end

  def self.root
    Rails.root
  end
end
