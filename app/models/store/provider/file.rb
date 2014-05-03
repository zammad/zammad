# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store::Provider::File

  def self.add(data, md5)
    write_to_fs(data, md5)
    true
  end

  def self.get(md5)
    read_from_fs(md5)
  end

  def self.delete(md5)
    unlink_from_fs(md5)
  end

  private

  # generate file location
  def self.get_locaton(md5)

    # generate directory
    base = Rails.root.to_s + '/storage/fs/'
    parts = md5.scan(/.{1,3}/)
    path = parts[ 1 .. 7 ].join('/') + '/'
    file = parts[ 8 .. parts.count ].join('')
    location = "#{base}/#{path}"

    # create directory if not exists
    if !File.exist?( location )
      FileUtils.mkdir_p( location )
    end
    location += file
  end

  # unlink file from fs
  def self.unlink_from_fs(md5)
    if File.exist?( get_locaton(md5) )
      puts "NOTICE: storge remove '#{ get_locaton(md5) }'"
      File.delete( get_locaton(md5) )
    end
  end

  # read file from fs
  def self.read_from_fs(md5)
    puts "read from fs #{ get_locaton(md5) }"
    if !File.exist?( get_locaton(md5) )
      raise "ERROR: No such file #{ get_locaton(md5) }"
    end
    data = File.open( get_locaton(md5), 'rb' )
    content = data.read

    # check md5
    local_md5 = Digest::MD5.hexdigest( content )
    if local_md5 != md5
      raise "ERROR: Corrupt file in fs #{ get_locaton(md5) }, md5 should be #{md5} but is #{local_md5}"
    end
    content
  end

  # write file to fs
  def self.write_to_fs(data,md5)

    # install file
    permission = '600'
    if !File.exist?( get_locaton(md5) )
      puts "NOTICE: storge write '#{ get_locaton(md5) }' (#{permission})"
      file = File.new( get_locaton(md5), 'wb' )
      file.write( data )
      file.close
    end
    File.chmod( permission.to_i(8), get_locaton(md5) )

    # check md5
    local_md5 = Digest::MD5.hexdigest( read_from_fs(md5) )
    if md5 != local_md5
      raise "ERROR: Corrupt file in fs #{ get_locaton(md5) }, md5 should be #{md5} but is #{local_md5}"
    end

    true
  end

end