# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class LongPollingController < ApplicationController

  # GET /api/message_send
  def message_send
    new_connection = false

    # check client id
    client_id = client_id_check
    if !client_id
      new_connection = true
      client_id = client_id_gen
      log 'notice', "new client connection", client_id
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

    # spool messages for new connects
    if params['data']['spool']
      msg = JSON.generate( params['data'] )
      Session.spool_create(msg)
    end

    # get spool messages and send them to new client connection
    if params['data']['action'] == 'spool'
      log 'notice', "request spool data", client_id

      if current_user
        spool = Session.spool_list( params['data']['timestamp'], current_user.id )
        spool.each { |item|
          if item[:type] == 'direct'
            log 'notice', "send spool to (user_id=#{ current_user.id })", client_id
            Session.send( client_id, item[:message] )
          else
            log 'notice', "send spool", client_id
            Session.send( client_id, item[:message] )
          end
        }
      end

      # send spool:sent event to client
      sleep 0.2
      log 'notice', "send spool:sent event", client_id
      Session.send( client_id, { :event => 'spool:sent', :data => { :timestamp => Time.now.to_i } } )
    end


    # receive message
    if params['data']['action'] == 'login'
      user_id = session[:user_id]
      user = {}
      if user_id
        user = User.user_data_full( user_id )
      end
      log 'notice', "send auth login (user_id #{user_id})", client_id
      Session.create( client_id, user, { :type => 'ajax' } )

      # broadcast
    elsif params['data']['action'] == 'broadcast'

      # list all current clients
      client_list = Session.list
      client_list.each {|local_client_id, local_client|
        if local_client_id != client_id

          # broadcast to recipient list
          if params['data']['recipient'] && params['data']['recipient']['user_id']
            params['data']['recipient']['user_id'].each { |user_id|
              if local_client[:user][:id] == user_id
                log 'notice', "send broadcast from (#{client_id.to_s}) to (user_id #{user_id})", local_client_id
                Session.send( local_client_id, params['data'] )
              end
            }
            # broadcast every client
          else
            log 'notice', "send broadcast from (#{client_id.to_s})", local_client_id
            Session.send( local_client_id, params['data'] )
          end
        else
          log 'notice', "do not send broadcast to it self", client_id
        end
      }
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

    # check queue to send
    client_id = client_id_check
    begin

      # update last ping
      sleep 1
      Session.touch( client_id )

      # set max loop time to 28 sec. because of 30 sec. timeout of mod_proxy
      count = 14
      while true
        count = count - 1
        queue = Session.queue( client_id )
        if queue && queue[0]
          #          puts "send " + queue.inspect + client_id.to_s
          render :json => queue
          return
        end
        sleep 2
        if count == 0
          render :json => { :action => 'pong' }
          return
        end
      end
    rescue Exception => e
      puts e.inspect
      puts e.backtrace
      render :json => { :error => 'Invalid client_id in receive loop!' }, :status => :unprocessable_entity
      return
    end
  end

  private
  def client_id_check
    return params[:client_id].to_s if params[:client_id]
    return
  end
  def client_id_gen
    rand(9999999999).to_s
  end
  def client_id_verify
    return if !params[:client_id]
    sessions = Session.sessions
    return if !sessions.include?( params[:client_id].to_s )
    return true
  end

  def log( level, data, client_id = '-' )
    if false
      return if level == 'debug'
    end
    puts "#{Time.now}:client(#{ client_id }) #{ data }"
    #      puts "#{Time.now}:#{ level }:client(#{ client_id }) #{ data }"
  end
end
