# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Store::File
  def initialize
    # get application root directory
    @root = Dir.pwd.to_s
    if @root.blank? || @root == '/'
      @root = Rails.root
    end

    # get working directories
    @path = "#{@root}/tmp/websocket_#{Rails.env}"
    @nodes_path = "#{@root}/tmp/session_node_#{Rails.env}"
  end

  def create(client_id, content)
    path         = "#{@path}/#{client_id}"
    path_tmp     = "#{@path}/tmp/#{client_id}"
    session_file = "#{path_tmp}/session"

    # store session data in session file
    FileUtils.mkpath path_tmp
    File.binwrite(session_file, content)

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

    FileUtils.mkdir_p path

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
    write_with_lock("#{path}/session", data.to_json)
  end

  def get(client_id)
    session_dir  = "#{@path}/#{client_id}"
    session_file = "#{session_dir}/session"
    data         = nil

    return if !check_session_file_for_client(client_id, session_dir, session_file)

    begin
      data_json = JSON.parse(read_with_lock(session_file))
      if data_json
        data        = Sessions.symbolize_keys(data_json)
        data[:user] = data_json['user'] # for compat. reasons
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
    location = new_message_filename_for(client_id)
    return false if !location

    begin
      write_with_lock(location, data.to_json)
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

    file_path = "#{path}/#{Time.now.utc.to_f}-#{SecureRandom.uuid}"
    write_with_lock(file_path, data.to_json)
  end

  def each_spool()
    path = "#{@path}/spool/"
    FileUtils.mkpath path

    files = []
    Dir.foreach(path) do |entry|
      next if entry == '.'
      next if entry == '..'

      files.push entry
    end
    files.sort.each do |entry|
      filename = "#{path}/#{entry}"
      next if !File.exist?(filename)

      message = read_with_lock(filename)
      yield message, entry
    end
  end

  def remove_from_spool(_message, entry)
    path = "#{@path}/spool/"
    FileUtils.rm "#{path}/#{entry}"
  end

  def clear_spool
    path = "#{@path}/spool/"
    FileUtils.rm_rf path
  end

  ### Node-specific methods ###

  def clear_nodes
    FileUtils.rm_rf @nodes_path
  end

  def nodes
    path = "#{@nodes_path}/*.status"
    nodes = []
    files = Dir.glob(path)
    files.each do |filename|
      begin
        content = read_with_lock(filename)
        data = JSON.parse(content)
        nodes.push data
      rescue => e
        Rails.logger.error "can't parse status file #{filename}, #{e.inspect}"
        # to_delete.push "#{path}/#{entry}"
        # next
      end
    end
    nodes
  end

  def add_node(node_id, data)

    FileUtils.mkdir_p @nodes_path

    status_file = "#{@nodes_path}/#{node_id}.status"

    content = data.to_json

    # store session data in session file
    write_with_lock(status_file, content)
  end

  def each_node_session()
    # read node sessions
    path = "#{@nodes_path}/*.session"

    files = Dir.glob(path)
    files.each do |filename|
      begin
        content = read_with_lock(filename)
        next if content.blank?

        data = JSON.parse(content)
        next if data.blank?

        yield data
      rescue => e
        Rails.logger.error "can't parse session file #{filename}, #{e.inspect}"
        # to_delete.push "#{path}/#{entry}"
        # next
      end
    end
  end

  def create_node_session(node_id, client_id, data)

    FileUtils.mkdir_p @nodes_path

    status_file = "#{@nodes_path}/#{node_id}.#{client_id}.session"
    content = data.to_json

    # store session data in session file
    write_with_lock(status_file, content)
  end

  def each_session_by_node(node_id)
    # read node sessions
    path = "#{@nodes_path}/#{node_id}.*.session"

    files = Dir.glob(path)
    files.each do |filename|
      begin
        content = read_with_lock(filename)
        next if content.blank?

        data = JSON.parse(content)
        next if data.blank?

        yield data
      rescue => e
        Rails.logger.error "can't parse session file #{filename}, #{e.inspect}"
        # to_delete.push "#{path}/#{entry}"
        # next
      end
    end
  end

  private

  def write_with_lock(filename, data)
    File.open(filename, 'ab') do |file|
      file.flock(File::LOCK_EX)
      file.truncate 0 # Truncate only after locking to avoid empty state
      file.write data
    end
  rescue Errno::ENOENT => e
    Rails.logger.debug { "Can't write data to web socket session file #{filename}, maybe the session was removed in the meantime: #{e.inspect}" }
    Rails.logger.debug e
  end

  def read_with_lock(filename)
    File.open(filename, 'rb') do |file|
      file.flock(File::LOCK_SH)
      return file.read
    end
  end

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

  def check_session_file_for_client(client_id, session_dir, session_file)
    # if no session dir exists, session got destoried
    if !File.exist?(session_dir)
      destroy(client_id)
      Sessions.log('debug', "missing session directory #{session_dir} for '#{client_id}', remove session.")
      return false
    end

    # if only session file is missing, then it's an error behavior
    if !File.exist?(session_file)
      destroy(client_id)
      Sessions.log('error', "missing session file for '#{client_id}', remove session.")
      return false
    end

    true
  end

  def new_message_filename_for(client_id)
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
    return nil if !File.directory? path

    location
  end
end
