# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sessions::Node

  @store = case Rails.application.config.websocket_session_store
           when :redis then Sessions::Store::Redis.new
           else Sessions::Store::File.new
           end

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
    @store.clear_nodes
  end

  def self.registered
    @store.nodes
  end

  def self.register(node_id)
    data = {
      updated_at_human: Time.now.utc,
      updated_at:       Time.now.utc.to_i,
      node_id:          node_id.to_s,
      pid:              $PROCESS_ID,
    }
    @store.add_node node_id, data
  end

  def self.stats
    sessions = {}
    @store.each_node_session do |data|
      next if data['client_id'].blank?

      sessions[data['client_id']] = data['node_id']
    end
    sessions
  end

  def self.sessions_for(node_id, client_id)
    # write node status file
    data = {
      updated_at_human: Time.now.utc,
      updated_at:       Time.now.utc.to_i,
      node_id:          node_id.to_s,
      client_id:        client_id.to_s,
      pid:              $PROCESS_ID,
    }
    @store.create_node_session node_id, client_id, data
  end

  def self.sessions_by(node_id, force = false)
    sessions = []
    @store.each_session_by_node(node_id) do |data|
      next if data['client_id'].blank?
      next if !Sessions.session_exists?(data['client_id']) && force == false

      sessions.push data['client_id']
    end
    sessions
  end

end
