# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Store::Provider::File

  # write file to fs
  def self.add(data, sha)

    # install file
    location = get_location(sha)
    permission = '600'

    # verify if file already is in file system and if it's not corrupt
    if File.exist?(location)
      begin
        get(sha)
      rescue
        delete(sha)
      end
    end

    # write file to file system
    if !File.exist?(location)
      Rails.logger.debug { "storage write '#{location}' (#{permission})" }
      file = File.new(location, 'wb')
      file.write(data)
      file.close
    end
    File.chmod(permission.to_i(8), location)

    # check sha
    local_sha = Digest::SHA256.hexdigest(get(sha))
    if sha != local_sha
      raise "Corrupt file in fs #{location}, sha should be #{sha} but is #{local_sha}"
    end

    true
  end

  # read file from fs
  def self.get(sha)
    location = get_location(sha)
    Rails.logger.debug { "read from fs #{location}" }
    if !File.exist?(location)
      raise "No such file #{location}"
    end

    data    = File.open(location, 'rb')
    content = data.read

    # check sha
    local_sha = Digest::SHA256.hexdigest(content)
    if local_sha != sha
      raise "Corrupt file in fs #{location}, sha should be #{sha} but is #{local_sha}"
    end

    content
  end

  # unlink file from fs
  def self.delete(sha)
    location = get_location(sha)
    if File.exist?(location)
      Rails.logger.info "storage remove '#{location}'"
      File.delete(location)
    end

    # check if dir need to be removed
    locations = location.split('/')
    (0..locations.count).reverse_each do |count|
      local_location = locations[0, count].join('/')
      break if local_location.match?(%r{storage/fs/{0,4}$})
      break if Dir["#{local_location}/*"].present?
      next if !Dir.exist?(local_location)

      FileUtils.rmdir(local_location)
    end
  end

  # generate file location
  def self.get_location(sha)

    # generate directory
    base = Rails.root.join('storage/fs').to_s
    parts = []
    length1 = 4
    length2 = 5
    length3 = 7
    last_position = 0

    # rubocop:disable Style/CombinableLoops
    (0..1).each do |_count|
      end_position = last_position + length1
      parts.push sha[last_position, length1]
      last_position = end_position
    end
    (0..1).each do |_count|
      end_position = last_position + length2
      parts.push sha[last_position, length2]
      last_position = end_position
    end
    (0..1).each do |_count|
      end_position = last_position + length3
      parts.push sha[last_position, length3]
      last_position = end_position
    end
    # rubocop:enable Style/CombinableLoops

    path     = "#{parts[ 0..6 ].join('/')}/"
    file     = sha[last_position, sha.length]
    location = "#{base}/#{path}"

    # create directory if not exists
    if !File.exist?(location)
      FileUtils.mkdir_p(location)
    end
    full_path = location + file
    full_path.gsub('//', '/')
  end

end
