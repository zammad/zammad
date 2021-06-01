# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Sessions::Node

  # get application root directory
  @root = Dir.pwd.to_s
  if @root.blank? || @root == '/'
    @root = Rails.root
  end

  # get working directories
  @path = "#{@root}/tmp/session_node_#{Rails.env}"

  def self.session_assigne(client_id, force = false)

    # get available nodes
    nodes = Sessions::Node.registered
    session_count = {}

    nodes.each do |node|
      count = Sessions::Node.sessions_by(node['node_id'], force).count
      session_count[node['node_id']] = count
    end

    # search for lowest session count
    node_id = nil
    node_count = nil
    session_count.each do |local_node_id, count|
      next if !node_count.nil? && count > node_count

      node_count = count
      node_id = local_node_id
    end

    # assigne session
    Rails.logger.info "Assigne session to node #{node_id} (#{client_id})"
    Sessions::Node.sessions_for(node_id, client_id)

    # write node status file
    node_id
  end

  def self.cleanup
    FileUtils.rm_rf @path
  end

  def self.registered
    path = "#{@path}/*.status"
    nodes = []
    files = Dir.glob(path)
    files.each do |filename|
      File.open(filename, 'rb') do |file|
        file.flock(File::LOCK_SH)
        content = file.read
        file.flock(File::LOCK_UN)
        begin
          data = JSON.parse(content)
          nodes.push data
        rescue => e
          Rails.logger.error "can't parse status file #{filename}, #{e.inspect}"
          #to_delete.push "#{path}/#{entry}"
          #next
        end
      end
    end
    nodes
  end

  def self.register(node_id)
    if !File.exist?(@path)
      FileUtils.mkpath @path
    end

    status_file = "#{@path}/#{node_id}.status"

    # write node status file
    data = {
      updated_at_human: Time.now.utc,
      updated_at:       Time.now.utc.to_i,
      node_id:          node_id.to_s,
      pid:              $PROCESS_ID,
    }
    content = data.to_json

    # store session data in session file
    File.open(status_file, 'wb') do |file|
      file.write content
    end

  end

  def self.stats
    # read node sessions
    path = "#{@path}/*.session"

    sessions = {}
    files = Dir.glob(path)
    files.each do |filename|
      File.open(filename, 'rb') do |file|
        file.flock(File::LOCK_SH)
        content = file.read
        file.flock(File::LOCK_UN)
        begin
          next if content.blank?

          data = JSON.parse(content)
          next if data.blank?
          next if data['client_id'].blank?

          sessions[data['client_id']] = data['node_id']
        rescue => e
          Rails.logger.error "can't parse session file #{filename}, #{e.inspect}"
          #to_delete.push "#{path}/#{entry}"
          #next
        end
      end
    end
    sessions
  end

  def self.sessions_for(node_id, client_id)
    if !File.exist?(@path)
      FileUtils.mkpath @path
    end

    status_file = "#{@path}/#{node_id}.#{client_id}.session"

    # write node status file
    data = {
      updated_at_human: Time.now.utc,
      updated_at:       Time.now.utc.to_i,
      node_id:          node_id.to_s,
      client_id:        client_id.to_s,
      pid:              $PROCESS_ID,
    }
    content = data.to_json

    # store session data in session file
    File.open(status_file, 'wb') do |file|
      file.write content
    end

  end

  def self.sessions_by(node_id, force = false)

    # read node sessions
    path = "#{@path}/#{node_id}.*.session"

    sessions = []
    files = Dir.glob(path)
    files.each do |filename|
      File.open(filename, 'rb') do |file|
        file.flock(File::LOCK_SH)
        content = file.read
        file.flock(File::LOCK_UN)
        begin
          next if content.blank?

          data = JSON.parse(content)
          next if data.blank?
          next if data['client_id'].blank?
          next if !Sessions.session_exists?(data['client_id']) && force == false

          sessions.push data['client_id']
        rescue => e
          Rails.logger.error "can't parse session file #{filename}, #{e.inspect}"
          #to_delete.push "#{path}/#{entry}"
          #next
        end
      end
    end
    sessions
  end

end
