# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Package < ApplicationModel
  include HasAuditLogs

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

Optionally, writing the package files to the file system can be skipped, e.g. in
container environments where the files are already part of the image:

  package = Package.install(file: '/path/to/package.zpm', write_files: false)

returns

  package # record of newly created package

Migrations will not be executed because the the codebase was modified
in the current process and is therefore inconsistent. This must be done
subsequently in a separate step.

=end

  def self.install(data)
    write_files = data.fetch(:write_files, true)

    if data[:file]
      json    = _read_file(data[:file], true)
      package = JSON.parse(json)
    elsif data[:string]
      package = JSON.parse(data[:string])
    end

    ensure_dependencies_install!(package['dependencies'])

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
        replacement:        true,
        remove_files:       write_files,
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
      _install_files(package_db, package['files'], write_files)

      # update package state
      package_db.reload
      package_db.state = 'installed'
      package_db.save
    end

    package_db
  end

  def self._install_files(package_db, files, write_files)
    files.each do |file|
      if !allowed_file_path?(file['location'])
        raise "Can't create file, because of not allowed file location: #{file['location']}!"
      end

      ensure_no_duplicate_files!(package_db.name, file['location'])

      next if !write_files

      permission = file['permission'] || '644'
      content    = Base64.decode64(file['content'])
      _write_file(file['location'], permission, content)
    end
  end

=begin

install or update all packages located in the given directory, in dependency order

  Package.install_dir('packages/install')

Optionally without writing the package files to the file system (see Package.install):

  Package.install_dir('packages/install', write_files: false)

Already installed packages with the same or a newer version are skipped.
Migrations will not be executed (see Package.install).

=end

  def self.install_dir(directory, write_files: true)
    _sort_by_dependencies(_packages_in_dir(directory)).each do |package|
      installed = Package.find_by(name: package['name'])

      if installed && Gem::Version.new(installed.version) >= Gem::Version.new(package['version'])
        logger.info "Package #{package['name']}-#{package['version']} is already installed."
        next
      end

      logger.info "Installing package #{package['name']}-#{package['version']}..."
      install(file: package['zpm_file'], write_files: write_files)

      # Dependency and duplicate file checks of subsequent packages must see this package.
      Auth::RequestCache.clear
    end
  end

=begin

uninstall all packages located in the given directory, in reverse dependency order

  Package.uninstall_dir('packages/uninstall')

Optionally without removing the package files from the file system (see Package.uninstall):

  Package.uninstall_dir('packages/uninstall', remove_files: false)

Packages which are not installed are skipped. The installed version is uninstalled,
regardless of the version of the .zpm file in the directory.
Down migrations are executed (see Package.uninstall).

=end

  def self.uninstall_dir(directory, remove_files: true)
    _sort_by_dependencies(_packages_in_dir(directory)).reverse_each do |package|
      installed = Package.find_by(name: package['name'])

      if !installed
        logger.info "Package #{package['name']} is not installed."
        next
      end

      logger.info "Uninstalling package #{installed.name}-#{installed.version}..."
      uninstall(name: installed.name, version: installed.version, remove_files: remove_files)

      # Dependency checks of subsequent packages must no longer see this package.
      Auth::RequestCache.clear
    end
  end

  def self._packages_in_dir(directory)
    Rails.root.join(directory).glob('*.zpm').map do |zpm_file|
      JSON.parse(File.read(zpm_file)).merge('zpm_file' => zpm_file.to_s)
    end
  end

  def self._sort_by_dependencies(packages)
    sorted_packages    = []
    remaining_packages = packages

    while remaining_packages.any?
      ready_packages = remaining_packages.select do |package|
        (package['dependencies'] || {}).keys.none? do |dependency_name|
          remaining_packages.any? { |candidate| candidate['name'] == dependency_name }
        end
      end

      raise "Circular dependencies between packages: #{remaining_packages.pluck('name').join(', ')}!" if ready_packages.empty?

      sorted_packages    += ready_packages
      remaining_packages -= ready_packages
    end

    sorted_packages
  end

  def self.ensure_dependencies_install!(dependencies)
    return if dependencies.blank?

    dependencies.each do |name, version_check|
      raise "Can't install package, because of invalid dependencies: #{name} #{version_check}!" if version_check !~ %r{^(>=|==|<=) (\d+\.\d+\.\d+)$}

      operator = $1
      version  = $2
      next if all_packages[name] && Gem::Version.new(all_packages[name]['version']).send(operator, Gem::Version.new(version))

      raise "Can't install package, because of missing dependencies: #{name} #{operator} #{version}!"
    end
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
      Package.all_packages.transform_values do |value|
        value['files'].pluck('location')
      end
    end
  end

  def self.all_packages
    Auth::RequestCache.fetch_value('Package/all_packages') do
      Package.all.each_with_object({}) do |package, result|
        json_file    = Package._get_bin(package.name, package.version)
        package_json = JSON.parse(json_file)
        result[package.name] = package_json
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

  def self.api_token
    ENV['PACKAGES_TOKEN'] || Setting.get('packages_token')
  end

  def self.api_version_name
    Rails.root.join('VERSION').read.chomp.split('.').tap { |row| row[2] = 'x' }[0..2].join('.')
  end

  def self.api_packages(params)
    return [] if api_token.blank?

    cache_key = "PackagesController/api_packages/#{api_token}/#{params.to_json}"
    cache     = Rails.cache.read(cache_key)
    return cache if !cache.nil?

    zip_file = api_zip_packages(params)
    return [] if zip_file.blank?

    result = []
    begin
      Zip::File.open(zip_file.path) do |zip|
        zip.sort.each do |entry|
          next if !entry.name.end_with?('.zpm')

          content = entry.get_input_stream.read
          data = JSON.parse(content)
          result << data
        end
      end
    ensure
      zip_file.close!
    end

    Rails.cache.write(cache_key, result, expires_in: 1.hour)
    result
  end

  def self.api_packages_hash(params)
    api_packages(params).index_by { |row| row['name'] }
  end

  def self.api_zip_packages(params)
    require 'zip'

    response = UserAgent.get('https://support.zammad.com/api/v1/addon_releases/download/organization', params, { bearer_token: api_token })
    return if !response.code.starts_with?('2')

    zip_file = Tempfile.new
    zip_file.binmode
    zip_file.write(response.body)
    zip_file.rewind
    zip_file
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

Optionally, removing the package files from the file system can be skipped, e.g. in
container environments where the files are part of the image:

  package = Package.uninstall(name: 'package', version: '0.1.1', remove_files: false)

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

    # on reinstall/replacement the package stays available to dependent packages
    ensure_dependencies_uninstall!(package['name']) if !data[:reinstall] && !data[:replacement]

    # down migrations
    if !data[:migration_not_down]
      Package::Migration.migrate(package['name'], 'reverse')
    end

    record = Package.find_by(
      name:    package['name'],
      version: package['version'],
    )

    if record.state == 'installed' && data.fetch(:remove_files, true)
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

  def self.ensure_dependencies_uninstall!(uninstall_name)
    all_packages.each do |name, data|
      next if data['dependencies'].blank?
      next if !data['dependencies'][uninstall_name]

      raise "Can't uninstall package, because of required dependencies: #{name} requires #{uninstall_name}!"
    end
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
