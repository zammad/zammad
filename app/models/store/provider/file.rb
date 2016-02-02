# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
class Store::Provider::File

  # write file to fs
  def self.add(data, sha)

    # install file
    permission = '600'
    if !File.exist?(get_locaton(sha))
      Rails.logger.debug "storge write '#{get_locaton(sha)}' (#{permission})"
      file = File.new(get_locaton(sha), 'wb')
      file.write(data)
      file.close
    end
    File.chmod(permission.to_i(8), get_locaton(sha))

    # check sha
    local_sha = Digest::SHA256.hexdigest(get(sha))
    if sha != local_sha
      fail "ERROR: Corrupt file in fs #{get_locaton(sha)}, sha should be #{sha} but is #{local_sha}"
    end

    true
  end

  # read file from fs
  def self.get(sha)
    Rails.logger.debug "read from fs #{get_locaton(sha)}"
    if !File.exist?(get_locaton(sha))
      fail "ERROR: No such file #{get_locaton(sha)}"
    end
    data    = File.open(get_locaton(sha), 'rb')
    content = data.read

    # check sha
    local_sha = Digest::SHA256.hexdigest(content)
    if local_sha != sha
      fail "ERROR: Corrupt file in fs #{get_locaton(sha)}, sha should be #{sha} but is #{local_sha}"
    end
    content
  end

  # unlink file from fs
  def self.delete(sha)
    if File.exist?( get_locaton(sha) )
      Rails.logger.info "storge remove '#{get_locaton(sha)}'"
      File.delete( get_locaton(sha) )
    end
  end

  # generate file location
  def self.get_locaton(sha)

    # generate directory
    base     = "#{Rails.root}/storage/fs/"
    parts    = sha.scan(/.{1,4}/)
    path     = parts[ 1..10 ].join('/') + '/'
    file     = parts[ 11..parts.count ].join('')
    location = "#{base}/#{path}"

    # create directory if not exists
    if !File.exist?(location)
      FileUtils.mkdir_p(location)
    end
    location += file
  end

end
