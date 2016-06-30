# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/
require 'exceptions'

class ApplicationController < ActionController::Base
  #  http_basic_authenticate_with :name => "test", :password => "ttt"

  helper_method :current_user,
                :authentication_check,
                :config_frontend,
                :http_log_config,
                :role?,
                :model_create_render,
                :model_update_render,
                :model_restory_render,
                :mode_show_rendeder,
                :model_index_render

  skip_before_action :verify_authenticity_token
  before_action :set_user, :session_update, :user_device_check, :cors_preflight_check
  after_action  :trigger_events, :http_log, :set_access_control_headers

  rescue_from StandardError, with: :server_error
  rescue_from ExecJS::RuntimeError, with: :server_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ArgumentError, with: :unprocessable_entity
  rescue_from Exceptions::UnprocessableEntity, with: :unprocessable_entity
  rescue_from Exceptions::NotAuthorized, with: :unauthorized

  # For all responses in this controller, return the CORS access control headers.
  def set_access_control_headers
    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Max-Age']           = '1728000'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control, Accept-Language'
    headers['Access-Control-Allow-Credentials'] = 'true'
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.

  def cors_preflight_check

    return if request.method != 'OPTIONS'

    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control, Accept-Language'
    headers['Access-Control-Max-Age']           = '1728000'
    headers['Access-Control-Allow-Credentials'] = 'true'
    render text: '', content_type: 'text/plain'

    false
  end

  def http_log_config(config)
    @http_log_support = config
  end

  private

  # execute events
  def trigger_events
    Observer::Transaction.commit
  end

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    return @_current_user if @_current_user
    return if !session[:user_id]
    @_current_user = User.lookup(id: session[:user_id])
  end

  def current_user_set(user)
    session[:user_id] = user.id
    @_current_user = user
    set_user
  end

  # Sets the current user into a named Thread location so that it can be accessed
  # by models and observers
  def set_user
    if !current_user
      UserInfo.current_user_id = 1
      return
    end
    UserInfo.current_user_id = current_user.id
  end

  # update session updated_at
  def session_update
    #sleep 0.6

    session[:ping] = Time.zone.now.iso8601

    # check if remote ip need to be updated
    if !session[:remote_ip] || session[:remote_ip] != request.remote_ip
      session[:remote_ip]  = request.remote_ip
      session[:geo]        = Service::GeoIp.location(request.remote_ip)
    end

    # fill user agent
    return if session[:user_agent]

    session[:user_agent] = request.env['HTTP_USER_AGENT']
  end

  # log http access
  def http_log
    return if !@http_log_support

    # request
    request_data = {
      content: '',
      content_type: request.headers['Content-Type'],
      content_encoding: request.headers['Content-Encoding'],
      source: request.headers['User-Agent'] || request.headers['Server'],
    }
    request.headers.each {|key, value|
      next if key[0, 5] != 'HTTP_'
      request_data[:content] += if key == 'HTTP_COOKIE'
                                  "#{key}: xxxxx\n"
                                else
                                  "#{key}: #{value}\n"
                                end
    }
    body = request.body.read
    if body
      request_data[:content] += "\n" + body
    end
    request_data[:content] = request_data[:content].slice(0, 8000)

    # response
    response_data = {
      code: response.status = response.code,
      content: '',
      content_type: nil,
      content_encoding: nil,
      source: nil,
    }
    response.headers.each {|key, value|
      response_data[:content] += "#{key}: #{value}\n"
    }
    body = response.body
    if body
      response_data[:content] += "\n" + body
    end
    response_data[:content] = response_data[:content].slice(0, 8000)
    record = {
      direction: 'in',
      facility: @http_log_support[:facility],
      url: url_for(only_path: false, overwrite_params: {}),
      status: response.status,
      ip: request.remote_ip,
      request: request_data,
      response: response_data,
      method: request.method,
    }
    HttpLog.create(record)
  end

  def user_device_check
    return false if !user_device_log(current_user, 'session')
    true
  end

  def user_device_log(user, type)
    switched_from_user_id = ENV['SWITCHED_FROM_USER_ID'] || session[:switched_from_user_id]
    return true if switched_from_user_id
    return true if !user

    time_to_check = true
    user_device_updated_at = session[:user_device_updated_at]
    if ENV['USER_DEVICE_UPDATED_AT']
      user_device_updated_at = Time.zone.parse(ENV['USER_DEVICE_UPDATED_AT'])
    end

    if user_device_updated_at
      # check if entry exists / only if write action
      diff = Time.zone.now - 10.minutes
      method = request.method
      if method == 'GET' || method == 'OPTIONS' || method == 'HEAD'
        diff = Time.zone.now - 30.minutes
      end

      # only update if needed
      if user_device_updated_at > diff
        time_to_check = false
      end
    end

    # if ip has not changed and ttl in still valid
    remote_ip = ENV['TEST_REMOTE_IP'] || request.remote_ip
    return true if time_to_check == false && session[:user_device_remote_ip] == remote_ip
    session[:user_device_remote_ip] = remote_ip

    # for sessions we need the fingperprint
    if type == 'session'
      if !session[:user_device_updated_at] && !params[:fingerprint] && !session[:user_device_fingerprint]
        raise Exceptions::UnprocessableEntity, 'Need fingerprint param!'
      end
      if params[:fingerprint]
        session[:user_device_fingerprint] = params[:fingerprint]
      end
    end

    session[:user_device_updated_at] = Time.zone.now

    # add device if needed
    http_user_agent = ENV['HTTP_USER_AGENT'] || request.env['HTTP_USER_AGENT']
    Delayed::Job.enqueue(
      Observer::UserDeviceLogJob.new(
        http_user_agent,
        remote_ip,
        user.id,
        session[:user_device_fingerprint],
        type,
      )
    )
  end

  def authentication_check_only(auth_param)

    #logger.debug 'authentication_check'
    #logger.debug params.inspect
    #logger.debug session.inspect
    #logger.debug cookies.inspect

    # already logged in, early exit
    if session.id && session[:user_id]
      logger.debug 'session based auth check'
      userdata = User.lookup(id: session[:user_id])
      current_user_set(userdata)
      logger.debug "session based auth for '#{userdata.login}'"
      return {
        auth: true
      }
    end

    error_message = 'authentication failed'

    # check sso based authentication
    sso_userdata = User.sso(params)
    if sso_userdata
      if check_maintenance_only(sso_userdata)
        return {
          auth: false,
          message: 'Maintenance mode enabled!',
        }
      end
      session[:persistent] = true
      return {
        auth: true
      }
    end

    # check http basic based authentication
    authenticate_with_http_basic do |username, password|
      logger.debug "http basic auth check '#{username}'"
      userdata = User.authenticate(username, password)
      next if !userdata
      if check_maintenance_only(userdata)
        return {
          auth: false,
          message: 'Maintenance mode enabled!',
        }
      end
      current_user_set(userdata)
      user_device_log(userdata, 'basic_auth')
      logger.debug "http basic auth for '#{userdata.login}'"
      return {
        auth: true
      }
    end

    # check http token based authentication
    if auth_param[:token_action]
      authenticate_with_http_token do |token, _options|
        logger.debug "token auth check '#{token}'"
        userdata = Token.check(
          action: auth_param[:token_action],
          name: token,
        )
        next if !userdata
        if check_maintenance_only(userdata)
          return {
            auth: false,
            message: 'Maintenance mode enabled!',
          }
        end
        current_user_set(userdata)
        user_device_log(userdata, 'token_auth')
        logger.debug "token auth for '#{userdata.login}'"
        return {
          auth: true
        }
      end
    end

    logger.debug error_message
    {
      auth: false,
      message: error_message,
    }
  end

  def authentication_check(auth_param = {})
    result = authentication_check_only(auth_param)

    # check if basic_auth fallback is possible
    if auth_param[:basic_auth_promt] && result[:auth] == false
      return request_http_basic_authentication
    end

    # return auth not ok
    if result[:auth] == false
      raise Exceptions::NotAuthorized, result[:message]
    end

    # return auth ok
    true
  end

  def role?(role_name)
    return false if !current_user
    current_user.role?(role_name)
  end

  def ticket_permission(ticket)
    return true if ticket.permission(current_user: current_user)
    raise Exceptions::NotAuthorized
  end

  def article_permission(article)
    ticket = Ticket.lookup(id: article.ticket_id)
    return true if ticket.permission(current_user: current_user)
    raise Exceptions::NotAuthorized
  end

  def deny_if_not_role(role_name)
    return false if role?(role_name)
    raise Exceptions::NotAuthorized
  end

  def valid_session_with_user
    return true if current_user
    raise Exceptions::UnprocessableEntity, 'No session user!'
  end

  def response_access_deny
    raise Exceptions::NotAuthorized
  end

  def config_frontend

    # config
    config = {}
    Setting.select('name').where(frontend: true).each { |setting|
      config[setting.name] = Setting.get(setting.name)
    }

    # remember if we can to swich back to user
    if session[:switched_from_user_id]
      config['switch_back_to_possible'] = true
    end

    # remember session_id for websocket logon
    config['session_id'] = session.id

    config
  end

  # model helper
  def model_create_render(object, params)

    clean_params = object.param_association_lookup(params)
    clean_params = object.param_cleanup(clean_params, true)

    # create object
    generic_object = object.new(clean_params)

    # save object
    generic_object.save!

    # set relations
    generic_object.param_set_associations(params)

    if params[:expand]
      render json: generic_object.attributes_with_relation_names, status: :created
      return
    end

    model_create_render_item(generic_object)
  end

  def model_create_render_item(generic_object)
    render json: generic_object.attributes_with_associations, status: :created
  end

  def model_update_render(object, params)

    # find object
    generic_object = object.find(params[:id])

    clean_params = object.param_association_lookup(params)
    clean_params = object.param_cleanup(clean_params, true)

    # save object
    generic_object.update_attributes!(clean_params)

    # set relations
    generic_object.param_set_associations(params)

    if params[:expand]
      render json: generic_object.attributes_with_relation_names, status: :ok
      return
    end

    model_update_render_item(generic_object)
  end

  def model_update_render_item(generic_object)
    render json: generic_object.attributes_with_associations, status: :ok
  end

  def model_destory_render(object, params)
    generic_object = object.find(params[:id])
    generic_object.destroy
    model_destory_render_item()
  end

  def model_destory_render_item ()
    render json: {}, status: :ok
  end

  def model_show_render(object, params)

    if params[:expand]
      generic_object = object.find(params[:id])
      render json: generic_object.attributes_with_relation_names, status: :ok
      return
    end

    if params[:full]
      generic_object_full = object.full(params[:id])
      render json: generic_object_full, status: :ok
      return
    end

    generic_object = object.find(params[:id])
    model_show_render_item(generic_object)
  end

  def model_show_render_item(generic_object)
    render json: generic_object.attributes_with_associations, status: :ok
  end

  def model_index_render(object, params)
    offset = 0
    per_page = 500
    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      limit = params[:per_page].to_i
    end
    generic_objects = if offset > 0
                        object.limit(params[:per_page]).offset(offset).limit(limit)
                      else
                        object.all.offset(offset).limit(limit)
                      end

    if params[:expand]
      list = []
      generic_objects.each {|generic_object|
        list.push generic_object.attributes_with_relation_names
      }
      render json: list, status: :ok
      return
    end

    if params[:full]
      assets = {}
      item_ids = []
      generic_objects.each {|item|
        item_ids.push item.id
        assets = item.assets(assets)
      }
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    generic_objects_with_associations = []
    generic_objects.each {|item|
      generic_objects_with_associations.push item.attributes_with_associations
    }
    model_index_render_result(generic_objects_with_associations)
  end

  def model_index_render_result(generic_objects)
    render json: generic_objects, status: :ok
  end

  def model_match_error(error)
    data = {
      error: error
    }
    if error =~ /(already exists|duplicate key|duplicate entry)/i
      data[:error_human] = 'Object already exists!'
    end
    data
  end

  def model_references_check(object, params)
    generic_object = object.find(params[:id])
    result = Models.references(object, generic_object.id)
    return false if result.empty?
    raise Exceptions::UnprocessableEntity, 'Can\'t delete, object has references.'
  rescue => e
    raise Exceptions::UnprocessableEntity, e
  end

  def not_found(e)
    logger.error e.message
    logger.error e.backtrace.inspect
    respond_to do |format|
      format.json { render json: model_match_error(e.message), status: :not_found }
      format.any {
        @exception = e
        @traceback = !Rails.env.production?
        file = File.open(Rails.root.join('public', '404.html'), 'r')
        render inline: file.read, status: :not_found
      }
    end
  end

  def unprocessable_entity(e)
    logger.error e.message
    logger.error e.backtrace.inspect
    respond_to do |format|
      format.json { render json: model_match_error(e.message), status: :unprocessable_entity }
      format.any {
        @exception = e
        @traceback = !Rails.env.production?
        file = File.open(Rails.root.join('public', '422.html'), 'r')
        render inline: file.read, status: :unprocessable_entity
      }
    end
  end

  def server_error(e)
    logger.error e.message
    logger.error e.backtrace.inspect
    respond_to do |format|
      format.json { render json: model_match_error(e.message), status: 500 }
      format.any {
        @exception = e
        @traceback = !Rails.env.production?
        file = File.open(Rails.root.join('public', '500.html'), 'r')
        render inline: file.read, status: 500
      }
    end
  end

  def unauthorized(e)
    respond_to do |format|
      format.json { render json: model_match_error(e.message), status: :unauthorized }
      format.any {
        @exception = e
        @traceback = !Rails.env.production?
        file = File.open(Rails.root.join('public', '401.html'), 'r')
        render inline: file.read, status: :unauthorized
      }
    end
  end

  # check maintenance mode
  def check_maintenance_only(user)
    return false if Setting.get('maintenance_mode') != true
    return false if user.role?('Admin')
    Rails.logger.info "Maintenance mode enabled, denied login for user #{user.login}, it's no admin user."
    true
  end

  def check_maintenance(user)
    return false if !check_maintenance_only(user)
    raise Exceptions::NotAuthorized, 'Maintenance mode enabled!'
  end

end
