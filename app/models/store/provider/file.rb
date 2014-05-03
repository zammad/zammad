# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store::Provider::File

  def self.add(data, sha)
    write_to_fs(data, sha)
    true
  end

  def self.get(sha)
    read_from_fs(sha)
  end

  def self.delete(sha)
    unlink_from_fs(sha)
  end

  private

  # generate file location
  def self.get_locaton(sha)

    # generate directory
    base = Rails.root.to_s + '/storage/fs/'
    parts = sha.scan(/.{1,3}/)
    path = parts[ 1 .. 10 ].join('/') + '/'
    file = parts[ 11 .. parts.count ].join('')
    location = "#{base}/#{path}"

    # create directory if not exists
    if !File.exist?( location )
      FileUtils.mkdir_p( location )
    end
    location += file
  end

  # unlink file from fs
  def self.unlink_from_fs(sha)
    if File.exist?( get_locaton(sha) )
      puts "NOTICE: storge remove '#{ get_locaton(sha) }'"
      File.delete( get_locaton(sha) )
    end
  end

  # read file from fs
  def self.read_from_fs(sha)
    puts "read from fs #{ get_locaton(sha) }"
    if !File.exist?( get_locaton(sha) )
      raise "ERROR: No such file #{ get_locaton(sha) }"
    end
    data = File.open( get_locaton(sha), 'rb' )
    content = data.read

    # check sha
    local_sha = Digest::SHA256.hexdigest( content )
    if local_sha != sha
      raise "ERROR: Corrupt file in fs #{ get_locaton(sha) }, sha should be #{sha} but is #{local_sha}"
    end
    content
  end

  # write file to fs
  def self.write_to_fs(data,sha)

    # install file
    permission = '600'
    if !File.exist?( get_locaton(sha) )
      puts "NOTICE: storge write '#{ get_locaton(sha) }' (#{permission})"
      file = File.new( get_locaton(sha), 'wb' )
      file.write( data )
      file.close
    end
    File.chmod( permission.to_i(8), get_locaton(sha) )

    # check sha
    local_sha = Digest::SHA256.hexdigest( read_from_fs(sha) )
    if sha != local_sha
      raise "ERROR: Corrupt file in fs #{ get_locaton(sha) }, sha should be #{sha} but is #{local_sha}"
    end

    true
  end

end