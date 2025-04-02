# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Package < ApplicationModel
  @@root = Rails.root.to_s # rubocop:disable Style/ClassVars

=begin

verify if package is installed correctly

  package = Package.find(123)

  issues = package.verify

returns:

    # if no issue exists
    nil

    # list of issues
    {
      'path/to/file' => 'missing',
      'path/to/file' => 'changed',
    }

=end

  def verify

    # get package
    json_file = self.class._get_bin(name, version)
    package   = JSON.parse(json_file)

    # verify installed files
    issues = {}
    package['files'].each do |file|
      if !File.exist?(file['location'])
        logger.error "File #{file['location']} is missing"
        issues[file['location']] = 'missing'
        next
      end
      content_package = Base64.decode64(file['content'])
      content_fs      = self.class._read_file(file['location'])
      next if content_package == content_fs

      logger.error "File #{file['location']} is different"
      issues[file['location']] = 'changed'
    end
    return nil if issues.blank?

    issues
  end

=begin

install all packages located under auto_install/*.zpm

  Package.auto_install

=end

  def self.auto_install
    path = "#{@@root}/auto_install/"
    return if !File.exist?(path)

    data = []
    Dir.foreach(path) do |entry|
      if entry.include?('.zpm') && entry !~ %r{^\.}
        data.push entry
      end
    end
    data.each do |file|
      install(file: "#{path}/#{file}")
    end
    data
  end

=begin

remove all linked files in application

note: will not take down package migrations, use Package.unlink instead

  Package.unlink_all

=end

  def self.unlink_all
    # link files
    Dir.glob("#{@@root}/**/*") do |entry|
      if File.symlink?(entry)
        logger.info "unlink: #{entry}"
        File.delete(entry)
      end
      backup_file = "#{entry}.link_backup"
      if File.exist?(backup_file)
        logger.info "Restore backup file of #{backup_file} -> #{entry}."
        File.rename(backup_file, entry)
      end
    end
  end

  # check if zpm is a package source repo
  def self._package_base_dir?(package_base_dir)
    package = false
    Dir.glob("#{package_base_dir}/*.szpm") do |entry|
      package = entry.sub(%r{^.*/(.+?)\.szpm$}, '\1')
    end
    if package == false
      raise "Can't link package, '#{package_base_dir}' is no package source directory!"
    end

    logger.debug { package.inspect }
    package
  end

=begin

execute migration down + unlink files

  Package.unlink('/path/to/src/extension')

=end

  def self.unlink(package_base_dir)

    # check if zpm is a package source repo
    package = _package_base_dir?(package_base_dir)

    # migration down
    Package::Migration.migrate(package, 'reverse')

    # link files
    Dir.glob("#{package_base_dir}/**/*") do |entry|
      entry = entry.sub('//', '/')
      file = entry
      file = file.sub(%r{#{package_base_dir}}, '')
      dest = "#{@@root}/#{file}"

      if File.symlink?(dest.to_s)
        logger.info "Unlink file: #{dest}"
        File.delete(dest.to_s)
      end

      backup_file = "#{dest}.link_backup"
      if File.exist?(backup_file)
        logger.info "Restore backup file of #{backup_file} -> #{dest}."
        File.rename(backup_file, dest.to_s)
      end
    end
  end

=begin

link files

  Package.link('/path/to/src/extension')

Migrations will not be executed because the the codebase was modified
in the current process and is therefore inconsistent. This must be done
subsequently in a separate step.

=end

  def self.link(package_base_dir)

    # link files
    Dir.glob("#{package_base_dir}/**/*") do |entry|
      entry = entry.sub('//', '/')
      file = entry
      file = file.sub(%r{#{package_base_dir}}, '')
      file = file.sub(%r{^/}, '')

      # ignore files
      if file.start_with?('README')
        logger.info "NOTICE: Ignore #{file}"
        next
      end

      # get new file destination
      dest = "#{@@root}/#{file}"

      if File.directory?(entry.to_s) && !File.exist?(dest.to_s)
        logger.info "Create dir: #{dest}"
        FileUtils.mkdir_p(dest.to_s)
      end

      if File.file?(entry.to_s) && File.file?(dest.to_s) && !File.symlink?(dest.to_s)
        backup_file = "#{dest}.link_backup"
        if File.exist?(backup_file)
          raise "Can't link #{entry} -> #{dest}, destination and .link_backup already exists!"
        end

        logger.info "Create backup file of #{dest} -> #{backup_file}."
        File.rename(dest.to_s, backup_file)
      end

      if File.file?(entry)
        if File.symlink?(dest.to_s)
          File.delete(dest.to_s)
        end
        logger.info "Link file: #{entry} -> #{dest}"
        File.symlink(entry.to_s, dest.to_s)
      end
    end
  end

=begin

install zpm package

  package = Package.install(file: '/path/to/package.zpm')

or

  package = Package.install(string: zpm_as_string)

returns

  package # record of newly created package

Migrations will not be executed because the the codebase was modified
in the current process and is therefore inconsistent. This must be done
subsequently in a separate step.

=end

  def self.install(data)
    if data[:file]
      json    = _read_file(data[:file], true)
      package = JSON.parse(json)
    elsif data[:string]
      package = JSON.parse(data[:string])
    end

    # package meta data
    meta = {
      name:          package['name'],
      version:       package['version'],
      vendor:        package['vendor'],
      url:           package['url'],
      state:         'uninstalled',
      created_by_id: 1,
      updated_by_id: 1,
    }

    # verify if package can get installed
    package_db = Package.find_by(name: meta[:name])
    if package_db
      if !data[:reinstall]
        if Gem::Version.new(package_db.version) == Gem::Version.new(meta[:version])
          raise "Package '#{meta[:name]}-#{meta[:version]}' already installed!"
        end
        if Gem::Version.new(package_db.version) > Gem::Version.new(meta[:version])
          raise "Newer version (#{package_db.version}) of package '#{meta[:name]}-#{meta[:version]}' already installed!"
        end
      end

      # uninstall files of old package
      uninstall(
        name:               package_db.name,
        version:            package_db.version,
        migration_not_down: true,
        reinstall:          data[:reinstall],
      )
    end

    Transaction.execute do
      # store package
      if !data[:reinstall]
        package_db = Package.create(meta)
        Store.create!(
          object:        'Package',
          o_id:          package_db.id,
          data:          package.to_json,
          filename:      "#{meta[:name]}-#{meta[:version]}.zpm",
          preferences:   {},
          created_by_id: UserInfo.current_user_id || 1,
        )
      end

      # write files
      package['files'].each do |file|
        if !allowed_file_path?(file['location'])
          raise "Can't create file, because of not allowed file location: #{file['location']}!"
        end

        ensure_no_duplicate_files!(package_db.name, file['location'])

        permission = file['permission'] || '644'
        content    = Base64.decode64(file['content'])
        _write_file(file['location'], permission, content)
      end

      # update package state
      package_db.reload
      package_db.state = 'installed'
      package_db.save
    end

    package_db
  end

  def self.ensure_no_duplicate_files!(name, location)
    all_files.each do |check_package, check_files|
      next if check_package == name
      next if check_files.exclude?(location)

      raise "Can't create file, because file '#{location}' is already provided by package '#{check_package}'!"
    end
  end

  def self.all_files
    Auth::RequestCache.fetch_value('Package/all_files') do
      Package.all.each_with_object({}) do |package, result|
        json_file    = Package._get_bin(package.name, package.version)
        package_json = JSON.parse(json_file)
        result[package.name] = package_json['files'].pluck('location')
      end
    end
  end

  def self.app_frontend_files?
    Auth::RequestCache.fetch_value('Package/app_frontend_files') do
      Package.all_files.values.flatten.any? { |f| f.starts_with?('app/frontend') }
    end
  end

  def self.gem_files?
    Dir['Gemfile.local.*'].present?
  end

  def self.app_package_installation?
    File.exist?('/usr/bin/zammad')
  end

=begin

reinstall package

  package = Package.reinstall(package_name)

returns

  package # record of newly created package

=end

  def self.reinstall(package_name)
    package = Package.find_by(name: package_name)
    if !package
      raise "No such package '#{package_name}'"
    end

    file = _get_bin(package.name, package.version)
    install(string: file, reinstall: true)
    package
  end

=begin

uninstall package

  package = Package.uninstall(name: 'package', version: '0.1.1')

or

  package = Package.uninstall(string: zpm_as_string)

returns

  package # record of newly created package

=end

  def self.uninstall(data)

    if data[:string]
      package = JSON.parse(data[:string])
    else
      json_file = _get_bin(data[:name], data[:version])
      package   = JSON.parse(json_file)
    end

    # down migrations
    if !data[:migration_not_down]
      Package::Migration.migrate(package['name'], 'reverse')
    end

    record = Package.find_by(
      name:    package['name'],
      version: package['version'],
    )

    if record.state == 'installed'
      package['files'].each do |file|
        permission = file['permission'] || '644'
        content    = Base64.decode64(file['content'])
        _delete_file(file['location'], permission, content)
      end
    end

    # delete package
    if data[:reinstall]
      record.update(state: 'uninstalled')
    else
      record.destroy
    end

    record
  end

=begin

execute all pending package migrations at once

  Package.migration_execute

=end

  def self.migration_execute
    Package.all.each do |package|
      json_file = Package._get_bin(package.name, package.version)
      package   = JSON.parse(json_file)
      Package::Migration.migrate(package['name'])
    end

    # sync package po files
    Translation.sync
  end

  def self._get_bin(name, version)
    package = Package.find_by(
      name:    name,
      version: version,
    )
    if !package
      raise "No such package '#{name}' version '#{version}'"
    end

    list = Store.list(
      object: 'Package',
      o_id:   package.id,
    )

    # find file
    if !list || !list.first
      raise "No such file in storage list #{name} #{version}"
    end
    if !list.first.content
      raise "No such file in storage #{name} #{version}"
    end

    list.first.content
  end

  def self._read_file(file, fullpath = false)
    location = case fullpath
               when false
                 "#{@@root}/#{file}"
               when true
                 file
               else
                 "#{fullpath}/#{file}"
               end

    File.binread(location)
  end

  def self._write_file(file, permission, data)
    location = "#{@@root}/#{file}"

    # rename existing file if not already the same file
    if File.exist?(location)
      backup_location = "#{location}.save"
      content_fs      = _read_file(file)
      if content_fs == data && File.exist?(backup_location)
        logger.debug { "NOTICE: file '#{location}' already exists, skip install" }
        return true
      end

      logger.info "NOTICE: backup old file '#{location}' to #{backup_location}"
      File.rename(location, backup_location)
    end

    # check if directories need to be created
    directories = location.split '/'
    (0..(directories.length - 2)).each do |position|
      tmp_path = ''
      (1..position).each do |count|
        tmp_path = "#{tmp_path}/#{directories[count]}"
      end

      next if tmp_path == ''
      next if File.exist?(tmp_path)

      Dir.mkdir(tmp_path, 0o755)
    end

    # install file
    logger.info "NOTICE: install '#{location}' (#{permission})"
    file = File.new(location, 'wb')
    file.write(data)
    file.close
    File.chmod(permission.to_s.to_i(8), location)
    true
  end

  def self._delete_file(file, _permission, _data)
    location = "#{@@root}/#{file}"

    # install file
    logger.info "NOTICE: uninstall '#{location}'"

    FileUtils.rm_rf(location)

    # rename existing file
    backup_location = "#{location}.save"
    if File.exist?(backup_location)
      logger.info "NOTICE: restore old file '#{backup_location}' to #{location}"
      File.rename(backup_location, location)
    end

    true
  end

  def self.allowed_file_path?(file)
    file.exclude?('..') && file.exclude?('%2e%2e')
  end
  private_class_method :allowed_file_path?
end
