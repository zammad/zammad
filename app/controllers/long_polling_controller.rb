class LongPollingController < ApplicationController

  # GET /api/message_send
  def message_send
    new_connection = false

    # check client id
    client_id = client_id_check
    if !client_id
      new_connection = true
      client_id = client_id_gen
      puts 'NEW CLIENT CONNECTION: ' + client_id.to_s
    else
      # cerify client id
      if !client_id_verify
        render :json => { :error => 'Invalid client_id in send!' }, :status => :unprocessable_entity
        return
      end
    end
    if !params['data']
      params['data'] = {}
    end

    # receive message
    if params['data']['action'] == 'login'
      user_id = session[:user_id]
      user = {}
      if user_id
        user = User.user_data_full( user_id )
      end
      Session.create( client_id, user, { :type => 'ajax' } )
    end

    if new_connection
      result = { :client_id => client_id }
      render :json => result
    else
      render :json => {}
    end
  end

  # GET /api/message_receive
  def message_receive

    # check client id
    if !client_id_verify
      render :json => { :error => 'Invalid client_id receive!' }, :status => :unprocessable_entity
      return
    end

    # check queue queue to send
    client_id = client_id_check
    begin
      count = 28
      while true
        count = count - 1
        queue = Session.queue( client_id )
        if queue && queue[0]
  #        puts "send " + queue.inspect + client_id.to_s
          render :json => queue
          return
        end
        sleep 2
        if count == 0
          render :json => { :action => 'pong' }
          return
        end
      end
    rescue
      render :json => { :error => 'Invalid client_id in receive loop!' }, :status => :unprocessable_entity
      return
    end
  end

  private
    def client_id_check
      return params[:client_id] if params[:client_id]
      return
    end
    def client_id_gen
      rand(99999999)
    end
    def client_id_verify
      return if !params[:client_id]
      sessions = Session.sessions
      return if !sessions.include?( params[:client_id].to_s )
#    Session.update( client_id )
#      Session.touch( params[:client_id] )
      return true
    end
end