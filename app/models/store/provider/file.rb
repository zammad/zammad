# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Store::Provider::File

  # write file to fs
  def self.add(data, sha)
    location = get_location(sha)

    # write file to file system
    if !File.exist?(location)
      Rails.logger.debug { "storge write '#{location}' (600)" }
      File.binwrite(location, data)
    end

    File.chmod(0o600, location)

    validate_file(sha)
  rescue # .validate_file will raise an error if contents do not match SHA
    delete(sha)

    fail_count ||= 0
    fail_count.zero? ? (fail_count += 1) && retry : raise
  end

  # read file from fs
  def self.get(sha)
    location = get_location(sha)

    Rails.logger.debug { "read from fs #{location}" }
    content   = File.binread(location)
    local_sha = Store::File.checksum(content)

    # check sha
    raise "File corrupted: path #{location} does not match SHA digest (#{local_sha})" if local_sha != sha

    content
  end

  class << self
    alias validate_file get
  end

  # unlink file from fs
  def self.delete(sha)
    location = get_location(sha)

    if File.exist?(location)
      Rails.logger.info "storage remove '#{location}'"
      File.delete(location)
    end

    # remove empty ancestor directories
    storage_fs_path = Rails.root.join('storage/fs')
    location.parent.ascend do |path|
      break if !Dir.empty?(path)
      break if path == storage_fs_path

      Dir.rmdir(path)
    end
  end

  # generate file location
  def self.get_location(sha)
    parts = sha.scan(%r{^(.{4})(.{4})(.{5})(.{5})(.{7})(.{7})(.*)}).first
    Rails.root.join('storage/fs', *parts).tap { |path| FileUtils.mkdir_p(path.parent) }
  end

end
