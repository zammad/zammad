# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sessions::Client

  def initialize(client_id, node_id)
    @client_id = client_id
    @node_id = node_id
    log '---client start ws connection---'
    fetch
    log '---client exiting ws connection---'
  end

  def fetch

    backends = [
      'Sessions::Backend::TicketOverviewList',
      'Sessions::Backend::ActivityStream',
    ]

    asset_lookup             = {}
    backend_pool             = []
    user_id_last_run         = nil
    user_updated_at_last_run = nil
    loop_count               = 0
    loop do

      # check if session still exists
      return if !Sessions.session_exists?(@client_id)

      # get connection user
      session_data = Sessions.get(@client_id)
      return if !session_data
      return if !session_data[:user]
      return if !session_data[:user]['id']

      user = User.lookup(id: session_data[:user]['id'])
      return if !user

      # init new backends
      if user_id_last_run != user.id
        user_id_last_run = user.id
        asset_lookup = {}

        # release old objects
        backend_pool.collect! do
          nil
        end

        # create new pool
        backend_pool = []
        backends.each do |backend|
          item = backend.constantize.new(user, asset_lookup, self, @client_id)
          backend_pool.push item
        end
      # update user if required
      elsif user_updated_at_last_run != user.updated_at
        user_updated_at_last_run = user.updated_at

        log "---client - updating user #{user.id} - #{user_updated_at_last_run}"
        backend_pool.each do |backend|
          backend.user = user
        end
      end

      loop_count += 1
      log "---client - looking for data of user #{user.id}"

      # push messages from backends
      backend_pool.each(&:push)

      log '---/client-'

      # start faster in the beginnig
      if loop_count < 20
        sleep 1
      else
        sleep 2.2
      end
    end
  end

  # send update to browser
  def send(data)
    Sessions.send(@client_id, data)
  end

  def log(msg)
    Rails.logger.debug { "client(#{@node_id}.#{@client_id}) #{msg}" }
  end
end
