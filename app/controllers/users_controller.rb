# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class UsersController < ApplicationController
  include ChecksUserAttributesByCurrentUserPermission

  prepend_before_action :authentication_check, except: %i[create password_reset_send password_reset_verify image]
  prepend_before_action :authentication_check_only, only: [:create]

  # @path       [GET] /users
  #
  # @summary          Returns a list of User records.
  # @notes            The requester has to be in the role 'Admin' or 'Agent' to
  #                   get a list of all Users. If the requester is in the
  #                   role 'Customer' only just the own User record will be returned.
  #
  # @response_message 200 [Array<User>] List of matching User records.
  # @response_message 401               Invalid session.
  def index
    offset = 0
    per_page = 500
    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      per_page = params[:per_page].to_i
    end

    if per_page > 500
      per_page = 500
    end

    # only allow customer to fetch him self
    users = if !current_user.permissions?(['admin.user', 'ticket.agent'])
              User.where(id: current_user.id).order(id: 'ASC').offset(offset).limit(per_page)
            else
              User.all.order(id: 'ASC').offset(offset).limit(per_page)
            end

    if response_expand?
      list = []
      users.each do |user|
        list.push user.attributes_with_association_names
      end
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      users.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    users_all = []
    users.each do |user|
      users_all.push User.lookup(id: user.id).attributes_with_association_ids
    end
    render json: users_all, status: :ok
  end

  # @path       [GET] /users/{id}
  #
  # @summary          Returns the User record with the requested identifier.
  # @notes            The requester has to be in the role 'Admin' or 'Agent' to
  #                   access all User records. If the requester is in the
  #                   role 'Customer' just the own User record is accessable.
  #
  # @parameter        id(required) [Integer] The identifier matching the requested User.
  # @parameter        full         [Bool]    If set a Asset structure with all connected Assets gets returned.
  #
  # @response_message 200 [User] User record matching the requested identifier.
  # @response_message 401        Invalid session.
  def show
    user = User.find(params[:id])
    access!(user, 'read')

    if response_expand?
      result = user.attributes_with_association_names
      result.delete('password')
      render json: result
      return
    end

    if response_full?
      result = {
        id:     user.id,
        assets: user.assets({}),
      }
      render json: result
      return
    end

    result = user.attributes_with_association_ids
    result.delete('password')
    render json: result
  end

  # @path      [POST] /users
  #
  # @summary          Creates a User record with the provided attribute values.
  # @notes            TODO.
  #
  # @parameter        User(required,body) [User] The attribute value structure needed to create a User record.
  #
  # @response_message 200 [User] Created User record.
  # @response_message 401        Invalid session.
  def create
    clean_params = User.association_name_to_id_convert(params)
    clean_params = User.param_cleanup(clean_params, true)

    # check if it's first user, the admin user
    # inital admin account
    count = User.all.count
    admin_account_exists = true
    if count <= 2
      admin_account_exists = false
    end

    # if it's a signup, add user to customer role
    if !current_user

      # check if feature is enabled
      if admin_account_exists && !Setting.get('user_create_account')
        raise Exceptions::UnprocessableEntity, 'Feature not enabled!'
      end

      # check signup option only after admin account is created
      if admin_account_exists && !params[:signup]
        raise Exceptions::UnprocessableEntity, 'Only signup with not authenticate user possible!'
      end

      # check if user already exists
      if clean_params[:email].blank?
        raise Exceptions::UnprocessableEntity, 'Attribute \'email\' required!'
      end

      # check if user already exists
      exists = User.find_by(email: clean_params[:email].downcase.strip)
      raise Exceptions::UnprocessableEntity, 'Email address is already used for other user.' if exists

      user = User.new(clean_params)
      user.associations_from_param(params)
      user.updated_by_id = 1
      user.created_by_id = 1

      # add first user as admin/agent and to all groups
      group_ids = []
      role_ids  = []
      if count <= 2
        Role.where(name: %w[Admin Agent]).each do |role|
          role_ids.push role.id
        end
        Group.all.each do |group|
          group_ids.push group.id
        end

        # everybody else will go as customer per default
      else
        role_ids = Role.signup_role_ids
      end
      user.role_ids  = role_ids
      user.group_ids = group_ids

      # remember source (in case show email verify banner)
      # if not inital user creation
      if admin_account_exists
        user.source = 'signup'
      end

    # else do assignment as defined
    else

      # permission check
      check_attributes_by_current_user_permission(params)

      user = User.new(clean_params)
      user.associations_from_param(params)
    end

    user.save!

    # if first user was added, set system init done
    if !admin_account_exists
      Setting.set('system_init_done', true)

      # fetch org logo
      if user.email.present?
        Service::Image.organization_suggest(user.email)
      end

      # load calendar
      Calendar.init_setup(request.remote_ip)

      # load text modules
      begin
        TextModule.load(request.env['HTTP_ACCEPT_LANGUAGE'] || 'en-us')
      rescue => e
        logger.error "Unable to load text modules #{request.env['HTTP_ACCEPT_LANGUAGE'] || 'en-us'}: #{e.message}"
      end
    end

    # send inviteation if needed / only if session exists
    if params[:invite].present? && current_user
      sleep 5 if ENV['REMOTE_URL'].present?
      token = Token.create(action: 'PasswordReset', user_id: user.id)
      NotificationFactory::Mailer.notification(
        template: 'user_invite',
        user: user,
        objects: {
          token: token,
          user: user,
          current_user: current_user,
        }
      )
    end

    # send email verify
    if params[:signup].present? && !current_user
      result = User.signup_new_token(user)
      NotificationFactory::Mailer.notification(
        template: 'signup',
        user: user,
        objects: result,
      )
    end

    if response_expand?
      user = user.reload.attributes_with_association_names
      user.delete('password')
      render json: user, status: :created
      return
    end

    if response_full?
      result = {
        id:     user.id,
        assets: user.assets({}),
      }
      render json: result, status: :created
      return
    end

    user = user.reload.attributes_with_association_ids
    user.delete('password')
    render json: user, status: :created
  end

  # @path       [PUT] /users/{id}
  #
  # @summary          Updates the User record matching the identifier with the provided attribute values.
  # @notes            TODO.
  #
  # @parameter        id(required)        [Integer] The identifier matching the requested User record.
  # @parameter        User(required,body) [User]    The attribute value structure needed to update a User record.
  #
  # @response_message 200 [User] Updated User record.
  # @response_message 401        Invalid session.
  def update
    user = User.find(params[:id])
    access!(user, 'change')

    # permission check
    check_attributes_by_current_user_permission(params)
    user.with_lock do
      clean_params = User.association_name_to_id_convert(params)
      clean_params = User.param_cleanup(clean_params, true)
      user.update!(clean_params)

      # presence and permissions were checked via `check_attributes_by_current_user_permission`
      privileged_attributes = params.slice(:role_ids, :roles, :group_ids, :groups, :organization_ids, :organizations)

      if privileged_attributes.present?
        user.associations_from_param(privileged_attributes)
      end
    end

    if response_expand?
      user = user.reload.attributes_with_association_names
      user.delete('password')
      render json: user, status: :ok
      return
    end

    if response_full?
      result = {
        id:     user.id,
        assets: user.assets({}),
      }
      render json: result, status: :ok
      return
    end

    user = user.reload.attributes_with_association_ids
    user.delete('password')
    render json: user, status: :ok
  end

  # @path    [DELETE] /users/{id}
  #
  # @summary          Deletes the User record matching the given identifier.
  # @notes            The requester has to be in the role 'Admin' to be able to delete a User record.
  #
  # @parameter        id(required) [User] The identifier matching the requested User record.
  #
  # @response_message 200 User successfully deleted.
  # @response_message 401 Invalid session.
  def destroy
    user = User.find(params[:id])
    access!(user, 'delete')

    model_references_check(User, params)
    model_destroy_render(User, params)
  end

  # @path       [GET] /users/me
  #
  # @summary          Returns the User record of current user.
  # @notes            The requestor need to have a valid authentication.
  #
  # @parameter        full         [Bool]    If set a Asset structure with all connected Assets gets returned.
  #
  # @response_message 200 [User] User record matching the requested identifier.
  # @response_message 401        Invalid session.
  def me

    if response_expand?
      user = current_user.attributes_with_association_names
      user.delete('password')
      render json: user, status: :ok
      return
    end

    if response_full?
      full = User.full(current_user.id)
      render json: full
      return
    end

    user = current_user.attributes_with_association_ids
    user.delete('password')
    render json: user
  end

  # @path       [GET] /users/search
  #
  # @tag Search
  # @tag User
  #
  # @summary          Searches the User matching the given expression(s).
  # @notes            TODO: It's possible to use the SOLR search syntax.
  #                   The requester has to be in the role 'Admin' or 'Agent' to
  #                   be able to search for User records.
  #
  # @parameter        query           [String]        The search query.
  # @parameter        limit           [Integer]       The limit of search results.
  # @parameter        role_ids(multi) [Array<String>] A list of Role identifiers to which the Users have to be allocated to.
  # @parameter        full            [Boolean]       Defines if the result should be
  #                                                   true: { user_ids => [1,2,...], assets => {...} }
  #                                                   or false: [{:id => user.id, :label => "firstname lastname <email>", :value => "firstname lastname <email>"},...].
  #
  # @response_message 200 [Array<User>] A list of User records matching the search term.
  # @response_message 401               Invalid session.
  def search

    if !current_user.permissions?(['ticket.agent', 'admin.user'])
      response_access_deny
      return
    end

    per_page = params[:per_page] || params[:limit] || 100
    per_page = per_page.to_i
    if per_page > 500
      per_page = 500
    end
    page = params[:page] || 1
    page = page.to_i
    offset = (page - 1) * per_page

    query = params[:query]
    if query.respond_to?(:permit!)
      query = query.permit!.to_h
    end

    # build result list
    tickets = Ticket.search(
      query: query,
      condition: params[:condition].to_h,
      limit: per_page,
      offset: offset,
      current_user: current_user,
    )

    query = params[:query] || params[:term]
    if query.respond_to?(:permit!)
      query = query.permit!.to_h
    end

    query_params = {
      query: query,
      limit: per_page,
      offset: offset,
      sort_by: params[:sort_by],
      order_by: params[:order_by],
      current_user: current_user,
    }
    %i[role_ids permissions].each do |key|
      next if params[key].blank?
      query_params[key] = params[key]
    end

    # do query
    user_all = User.search(query_params)

    # do pagination if needed
    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      user_all = user_all[offset, params[:per_page].to_i] || []
    end

    if response_expand?
      list = []
      user_all.each do |user|
        list.push user.attributes_with_association_names
      end
      render json: list, status: :ok
      return
    end

    # build result list
    if params[:label] || params[:term]
      users = []
      user_all.each do |user|
        realname = user.fullname
        if user.email.present? && realname != user.email
          realname = "#{realname} <#{user.email}>"
        end
        a = if params[:term]
              { id: user.id, label: realname, value: user.email }
            else
              { id: user.id, label: realname, value: realname }
            end
        users.push a
      end

      # return result
      render json: users
      return
    end

    if response_full?
      user_ids = []
      assets   = {}
      user_all.each do |user|
        assets = user.assets(assets)
        user_ids.push user.id
      end

      # return result
      render json: {
        assets: assets,
        user_ids: user_ids.uniq,
      }
      return
    end

    list = []
    user_all.each do |user|
      list.push user.attributes_with_association_ids
    end
    render json: list, status: :ok
  end

  # @path       [GET] /users/recent
  #
  # @tag Search
  # @tag User
  #
  # @summary          Recent creates Users.
  # @notes            Recent creates Users.
  #
  # @parameter        limit           [Integer]       The limit of search results.
  # @parameter        role_ids(multi) [Array<String>] A list of Role identifiers to which the Users have to be allocated to.
  # @parameter        full            [Boolean]       Defines if the result should be
  #                                                   true: { user_ids => [1,2,...], assets => {...} }
  #                                                   or false: [{:id => user.id, :label => "firstname lastname <email>", :value => "firstname lastname <email>"},...].
  #
  # @response_message 200 [Array<User>] A list of User records matching the search term.
  # @response_message 401               Invalid session.
  def recent

    if !current_user.permissions?('admin.user')
      response_access_deny
      return
    end

    # do query
    user_all = if params[:role_ids].present?
                 User.joins(:roles).where('roles.id' => params[:role_ids]).where('users.id != 1').order('users.created_at DESC').limit(params[:limit] || 20)
               else
                 User.where('id != 1').order('created_at DESC').limit(params[:limit] || 20)
               end

    # build result list
    if !response_full?
      users = []
      user_all.each do |user|
        realname = user.firstname.to_s + ' ' + user.lastname.to_s
        if user.email && user.email.to_s != ''
          realname = realname + ' <' + user.email.to_s + '>'
        end
        a = { id: user.id, label: realname, value: realname }
        users.push a
      end

      # return result
      render json: users
      return
    end

    user_ids = []
    assets   = {}
    user_all.each do |user|
      assets = user.assets(assets)
      user_ids.push user.id
    end

    # return result
    render json: {
      assets: assets,
      user_ids: user_ids.uniq,
    }
  end

  # @path       [GET] /users/history/{id}
  #
  # @tag History
  # @tag User
  #
  # @summary          Returns the History records of a User record matching the given identifier.
  # @notes            The requester has to be in the role 'Admin' or 'Agent' to
  #                   get the History records of a User record.
  #
  # @parameter        id(required) [Integer] The identifier matching the requested User record.
  #
  # @response_message 200 [History] The History records of the requested User record.
  # @response_message 401           Invalid session.
  def history

    # permission check
    if !current_user.permissions?(['admin.user', 'ticket.agent'])
      response_access_deny
      return
    end

    # get user data
    user = User.find(params[:id])

    # get history of user
    history = user.history_get(true)

    # return result
    render json: history
  end

=begin

Resource:
POST /api/v1/users/email_verify

Payload:
{
  "token": "SoMeToKeN",
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/email_verify -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"token": "SoMeToKeN"}'

=end

  def email_verify
    raise Exceptions::UnprocessableEntity, 'No token!' if !params[:token]

    user = User.signup_verify_via_token(params[:token], current_user)
    raise Exceptions::UnprocessableEntity, 'Invalid token!' if !user

    render json: { message: 'ok', user_email: user.email }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/email_verify_send

Payload:
{
  "email": "some_email@example.com"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/email_verify_send -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"email": "some_email@example.com"}'

=end

  def email_verify_send

    raise Exceptions::UnprocessableEntity, 'No email!' if !params[:email]

    # check is verify is possible to send
    user = User.find_by(email: params[:email].downcase)
    raise Exceptions::UnprocessableEntity, 'No such user!' if !user

    #if user.verified == true
    #  render json: { error: 'Already verified!' }, status: :unprocessable_entity
    #  return
    #end

    token = Token.create(action: 'Signup', user_id: user.id)

    result = User.signup_new_token(user)
    if result && result[:token]
      user = result[:user]
      NotificationFactory::Mailer.notification(
        template: 'signup',
        user: user,
        objects: result
      )

      # only if system is in develop mode, send token back to browser for browser tests
      if Setting.get('developer_mode') == true
        render json: { message: 'ok', token: result[:token].name }, status: :ok
        return
      end

      # token sent to user, send ok to browser
      render json: { message: 'ok' }, status: :ok
      return
    end

    # unable to generate token
    render json: { message: 'failed' }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/password_reset

Payload:
{
  "username": "some user name"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/password_reset -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"username": "some_username"}'

=end

  def password_reset_send

    # check if feature is enabled
    raise Exceptions::UnprocessableEntity, 'Feature not enabled!' if !Setting.get('user_lost_password')

    result = User.password_reset_new_token(params[:username])
    if result && result[:token]

      # send mail
      user = result[:user]
      NotificationFactory::Mailer.notification(
        template: 'password_reset',
        user: user,
        objects: result
      )

      # only if system is in develop mode, send token back to browser for browser tests
      if Setting.get('developer_mode') == true
        render json: { message: 'ok', token: result[:token].name }, status: :ok
        return
      end

      # token sent to user, send ok to browser
      render json: { message: 'ok' }, status: :ok
      return
    end

    # unable to generate token
    render json: { message: 'failed' }, status: :ok
  end

=begin

Resource:
POST /api/v1/users/password_reset_verify

Payload:
{
  "token": "SoMeToKeN",
  "password": "new_password"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/password_reset_verify -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"token": "SoMeToKeN", "password" "new_password"}'

=end

  def password_reset_verify
    if params[:password]

      # check password policy
      result = password_policy(params[:password])
      if result != true
        render json: { message: 'failed', notice: result }, status: :ok
        return
      end

      # set new password with token
      user = User.password_reset_via_token(params[:token], params[:password])

      # send mail
      if user
        NotificationFactory::Mailer.notification(
          template: 'password_change',
          user: user,
          objects: {
            user: user,
            current_user: current_user,
          }
        )
      end

    else
      user = User.by_reset_token(params[:token])
    end
    if user
      render json: { message: 'ok', user_login: user.login }, status: :ok
    else
      render json: { message: 'failed' }, status: :ok
    end
  end

=begin

Resource:
POST /api/v1/users/password_change

Payload:
{
  "password_old": "some_password_old",
  "password_new": "some_password_new"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/password_change -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"password_old": "password_old", "password_new": "password_new"}'

=end

  def password_change

    # check old password
    if !params[:password_old]
      render json: { message: 'failed', notice: ['Current password needed!'] }, status: :ok
      return
    end
    user = User.authenticate(current_user.login, params[:password_old])
    if !user
      render json: { message: 'failed', notice: ['Current password is wrong!'] }, status: :ok
      return
    end

    # set new password
    if !params[:password_new]
      render json: { message: 'failed', notice: ['Please supply your new password!'] }, status: :ok
      return
    end

    # check password policy
    result = password_policy(params[:password_new])
    if result != true
      render json: { message: 'failed', notice: result }, status: :ok
      return
    end

    user.update!(password: params[:password_new])

    NotificationFactory::Mailer.notification(
      template: 'password_change',
      user: user,
      objects: {
        user: user,
        current_user: current_user,
      }
    )

    render json: { message: 'ok', user_login: user.login }, status: :ok
  end

=begin

Resource:
PUT /api/v1/users/preferences

Payload:
{
  "language": "de",
  "notification": true
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/preferences -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"language": "de", "notifications": true}'

=end

  def preferences
    raise Exceptions::UnprocessableEntity, 'No current user!' if !current_user

    preferences_params = params.except(:controller, :action)

    if preferences_params.present?
      user = User.find(current_user.id)
      user.with_lock do
        preferences_params.permit!.to_h.each do |key, value|
          user.preferences[key.to_sym] = value
        end
        user.save!
      end
    end
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
PUT /api/v1/users/out_of_office

Payload:
{
  "out_of_office": true,
  "out_of_office_start_at": true,
  "out_of_office_end_at": true,
  "out_of_office_replacement_id": 123,
  "out_of_office_text": 'honeymoon'
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/out_of_office -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"out_of_office": true, "out_of_office_replacement_id": 123}'

=end

  def out_of_office
    raise Exceptions::UnprocessableEntity, 'No current user!' if !current_user
    user = User.find(current_user.id)
    user.with_lock do
      user.assign_attributes(
        out_of_office:                params[:out_of_office],
        out_of_office_start_at:       params[:out_of_office_start_at],
        out_of_office_end_at:         params[:out_of_office_end_at],
        out_of_office_replacement_id: params[:out_of_office_replacement_id],
      )
      user.preferences[:out_of_office_text] = params[:out_of_office_text]
      user.save!
    end
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
DELETE /api/v1/users/account

Payload:
{
  "provider": "twitter",
  "uid": 581482342942
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/account -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"provider": "twitter", "uid": 581482342942}'

=end

  def account_remove
    raise Exceptions::UnprocessableEntity, 'No current user!' if !current_user

    # provider + uid to remove
    raise Exceptions::UnprocessableEntity, 'provider needed!' if !params[:provider]
    raise Exceptions::UnprocessableEntity, 'uid needed!' if !params[:uid]

    # remove from database
    record = Authorization.where(
      user_id: current_user.id,
      provider: params[:provider],
      uid: params[:uid],
    )
    raise Exceptions::UnprocessableEntity, 'No record found!' if !record.first

    record.destroy_all
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
GET /api/v1/users/image/8d6cca1c6bdc226cf2ba131e264ca2c7

Response:
<IMAGE>

Test:
curl http://localhost/api/v1/users/image/8d6cca1c6bdc226cf2ba131e264ca2c7 -v -u #{login}:#{password}

=end

  def image

    # cache image
    response.headers['Expires']       = 1.year.from_now.httpdate
    response.headers['Cache-Control'] = 'cache, store, max-age=31536000, must-revalidate'
    response.headers['Pragma']        = 'cache'

    file = Avatar.get_by_hash(params[:hash])
    if file
      send_data(
        file.content,
        filename: file.filename,
        type: file.preferences['Content-Type'] || file.preferences['Mime-Type'],
        disposition: 'inline'
      )
      return
    end

    # serve default image
    image = 'R0lGODdhMAAwAOMAAMzMzJaWlr6+vqqqqqOjo8XFxbe3t7GxsZycnAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAMAAwAAAEcxDISau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru98TwuAA+KQAQqJK8EAgBAgMEqmkzUgBIeSwWGZtR5XhSqAULACCoGCJGwlm1MGQrq9RqgB8fm4ZTUgDBIEcRR9fz6HiImKi4yNjo+QkZKTlJWWkBEAOw=='
    send_data(
      Base64.decode64(image),
      filename: 'image.gif',
      type: 'image/gif',
      disposition: 'inline'
    )
  end

=begin

Resource:
POST /api/v1/users/avatar

Payload:
{
  "avatar_full": "base64 url",
}

Response:
{
  message: 'ok'
}

Test:
curl http://localhost/api/v1/users/avatar -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"avatar": "base64 url"}'

=end

  def avatar_new
    return if !valid_session_with_user

    # get & validate image
    file_full   = StaticAssets.data_url_attributes(params[:avatar_full])
    file_resize = StaticAssets.data_url_attributes(params[:avatar_resize])

    avatar = Avatar.add(
      object: 'User',
      o_id: current_user.id,
      full: {
        content: file_full[:content],
        mime_type: file_full[:mime_type],
      },
      resize: {
        content: file_resize[:content],
        mime_type: file_resize[:mime_type],
      },
      source: 'upload ' + Time.zone.now.to_s,
      deletable: true,
    )

    # update user link
    user = User.find(current_user.id)
    user.update!(image: avatar.store_hash)

    render json: { avatar: avatar }, status: :ok
  end

  def avatar_set_default
    return if !valid_session_with_user

    # get & validate image
    raise Exceptions::UnprocessableEntity, 'No id of avatar!' if !params[:id]

    # set as default
    avatar = Avatar.set_default('User', current_user.id, params[:id])

    # update user link
    user = User.find(current_user.id)
    user.update!(image: avatar.store_hash)

    render json: {}, status: :ok
  end

  def avatar_destroy
    return if !valid_session_with_user

    # get & validate image
    raise Exceptions::UnprocessableEntity, 'No id of avatar!' if !params[:id]

    # remove avatar
    Avatar.remove_one('User', current_user.id, params[:id])

    # update user link
    avatar = Avatar.get_default('User', current_user.id)
    user = User.find(current_user.id)
    user.update!(image: avatar.store_hash)

    render json: {}, status: :ok
  end

  def avatar_list
    return if !valid_session_with_user

    # list of avatars
    result = Avatar.list('User', current_user.id)
    render json: { avatars: result }, status: :ok
  end

  # @path    [GET] /users/import_example
  #
  # @summary          Download of example CSV file.
  # @notes            The requester have 'admin.user' permissions to be able to download it.
  # @example          curl -u 'me@example.com:test' http://localhost:3000/api/v1/users/import_example
  #
  # @response_message 200 File download.
  # @response_message 401 Invalid session.
  def import_example
    permission_check('admin.user')
    send_data(
      User.csv_example,
      filename: 'user-example.csv',
      type: 'text/csv',
      disposition: 'attachment'
    )
  end

  # @path    [POST] /users/import
  #
  # @summary          Starts import.
  # @notes            The requester have 'admin.text_module' permissions to be create a new import.
  # @example          curl -u 'me@example.com:test' -F 'file=@/path/to/file/users.csv' 'https://your.zammad/api/v1/users/import?try=true'
  # @example          curl -u 'me@example.com:test' -F 'file=@/path/to/file/users.csv' 'https://your.zammad/api/v1/users/import'
  #
  # @response_message 201 Import started.
  # @response_message 401 Invalid session.
  def import_start
    permission_check('admin.user')
    string = params[:data] || params[:file].read.force_encoding('utf-8')
    result = User.csv_import(
      string: string,
      parse_params: {
        col_sep: params[:col_sep] || ',',
      },
      try: params[:try],
      delete: params[:delete],
    )
    render json: result, status: :ok
  end

  private

  def password_policy(password)
    if Setting.get('password_min_size').to_i > password.length
      return ["Can\'t update password, it must be at least %s characters long!", Setting.get('password_min_size')]
    end
    if Setting.get('password_need_digit').to_i == 1 && password !~ /\d/
      return ["Can't update password, it must contain at least 1 digit!"]
    end
    if Setting.get('password_min_2_lower_2_upper_characters').to_i == 1 && ( password !~ /[A-Z].*[A-Z]/ || password !~ /[a-z].*[a-z]/ )
      return ["Can't update password, it must contain at least 2 lowercase and 2 uppercase characters!"]
    end
    true
  end
end
