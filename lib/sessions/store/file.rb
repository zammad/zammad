class Sessions::Store::File
  def initialize
    # get application root directory
    @root = Dir.pwd.to_s
    if @root.blank? || @root == '/'
      @root = Rails.root
    end

    # get working directories
    @path = "#{@root}/tmp/websocket_#{Rails.env}"
  end

  def create(client_id, content)
    path         = "#{@path}/#{client_id}"
    path_tmp     = "#{@path}/tmp/#{client_id}"
    session_file = "#{path_tmp}/session"

    # store session data in session file
    FileUtils.mkpath path_tmp
    File.open(session_file, 'wb') do |file|
      file.write content
    end

    # destroy old session if needed
    if File.exist?(path)
      destroy(client_id)
    end

    # move to destination directory
    FileUtils.mv(path_tmp, path)
  end

  def sessions
    path = "#{@path}/"

    # just make sure that spool path exists
    if !File.exist?(path)
      FileUtils.mkpath path
    end

    data = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'
      next if entry == 'tmp'
      next if entry == 'spool'

      data.push entry.to_s
    end
    data
  end

  def session_exists?(client_id)
    session_dir = "#{@path}/#{client_id}"
    return false if !File.exist?(session_dir)

    session_file = "#{session_dir}/session"
    return false if !File.exist?(session_file)

    true
  end

  def destroy(client_id)
    path = "#{@path}/#{client_id}"
    FileUtils.rm_rf path
  end
  
  def set(client_id, data)
    path = "#{@path}/#{client_id}"
    File.open("#{path}/session", 'wb' ) do |file|
      file.flock(File::LOCK_EX)
      file.write data.to_json
      file.flock(File::LOCK_UN)
    end
  end

  def get(client_id)
    session_dir  = "#{@path}/#{client_id}"
    session_file = "#{session_dir}/session"
    data         = nil

    # if no session dir exists, session got destoried
    if !File.exist?(session_dir)
      destroy(client_id)
      Sessions.log('debug', "missing session directory #{session_dir} for '#{client_id}', remove session.")
      return
    end

    # if only session file is missing, then it's an error behavior
    if !File.exist?(session_file)
      destroy(client_id)
      Sessions.log('error', "missing session file for '#{client_id}', remove session.")
      return
    end
    begin
      File.open(session_file, 'rb') do |file|
        file.flock(File::LOCK_SH)
        all = file.read
        file.flock(File::LOCK_UN)
        data_json = JSON.parse(all)
        if data_json
          data        = Sessions.symbolize_keys(data_json)
          data[:user] = data_json['user'] # for compat. reasons
        end
      end
    rescue => e
      Sessions.log('error', e.inspect)
      destroy(client_id)
      Sessions.log('error', "error in reading/parsing session file '#{session_file}', remove session.")
      return
    end
    data
  end

  def send_data(client_id, data)
    path     = "#{@path}/#{client_id}/"
    filename = "send-#{Time.now.utc.to_f}"
    location = "#{path}#{filename}"
    check    = true
    count    = 0
    while check
      if File.exist?(location)
        count += 1
        location = "#{path}#{filename}-#{count}"
      else
        check = false
      end
    end
    return false if !File.directory? path

    begin
      File.open(location, 'wb') do |file|
        file.flock(File::LOCK_EX)
        file.write data.to_json
        file.flock(File::LOCK_UN)
        file.close
      end
    rescue => e
      Sessions.log('error', e.inspect)
      Sessions.log('error', "error in writing message file '#{location}'")
      return false
    end
    true
  end

  def queue(client_id)
    path  = "#{@path}/#{client_id}/"
    data  = []
    files = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'

      files.push entry
    end
    files.sort.each do |entry|
      next if !entry.start_with?('send')

      message = queue_file_read(path, entry)
      next if !message

      data.push message
    end
    data
  end

  def cleanup
    return true if !File.exist?(@path)

    FileUtils.rm_rf @path
    true
  end

  def add_to_spool(data)
    path = "#{@path}/spool/"
    FileUtils.mkpath path

    file_path = "#{path}/#{Time.now.utc.to_f}-#{rand(99_999)}"
    File.open(file_path, 'wb') do |file|
      file.flock(File::LOCK_EX)
      file.write data.to_json
      file.flock(File::LOCK_UN)
    end
  end

  def each_spool(&block)
    path = "#{@path}/spool/"
    FileUtils.mkpath path

    files     = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'

      files.push entry
    end
    files.sort.each do |entry|
      filename = "#{path}/#{entry}"
      next if !File.exist?(filename)

      File.open(filename, 'rb') do |file|
        file.flock(File::LOCK_SH)
        message = file.read
        file.flock(File::LOCK_UN)

        block.call message
      end
    end
  end

  def remove_from_spool(entry)
    File.remove "#{path}/#{entry}"
  end

  def clear_spool
    path = "#{@path}/spool/"
    FileUtils.rm_rf path
  end

  private

  def queue_file_read(path, filename)
    location = "#{path}#{filename}"
    message = ''
    File.open(location, 'rb') do |file|
      file.flock(File::LOCK_EX)
      message = file.read
      file.flock(File::LOCK_UN)
    end
    File.delete(location)
    return if message.blank?

    begin
      JSON.parse(message)
    rescue => e
      Sessions.log('error', "can't parse queue message: #{message}, #{e.inspect}")
      nil
    end
  end
end