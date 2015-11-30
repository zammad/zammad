# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UsersController < ApplicationController
  before_action :authentication_check, except: [:create, :password_reset_send, :password_reset_verify, :image]

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

    # only allow customer to fetch him self
    if role?(Z_ROLENAME_CUSTOMER) && !role?(Z_ROLENAME_ADMIN) && !role?('Agent')
      users = User.where( id: current_user.id )
    else
      users = User.all
    end
    users_all = []
    users.each {|user|
      users_all.push User.lookup( id: user.id ).attributes_with_associations
    }
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

    # access deny
    return if !permission_check

    if params[:full]
      full = User.full( params[:id] )
      render json: full
      return
    end

    user = User.find( params[:id] )
    render json: user
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
    user = User.new( User.param_cleanup(params, true) )

    begin
      # check if it's first user
      count = User.all.count()

      # if it's a signup, add user to customer role
      if !current_user
        user.updated_by_id = 1
        user.created_by_id = 1

        # check if feature is enabled
        if !Setting.get('user_create_account')
          render json: { error: 'Feature not enabled!' }, status: :unprocessable_entity
          return
        end

        # add first user as admin/agent and to all groups
        group_ids = []
        role_ids  = []
        if count <= 2
          Role.where( name: [ Z_ROLENAME_ADMIN, 'Agent'] ).each { |role|
            role_ids.push role.id
          }
          Group.all().each { |group|
            group_ids.push group.id
          }

          # everybody else will go as customer per default
        else
          role_ids.push Role.where( name: Z_ROLENAME_CUSTOMER ).first.id
        end
        user.role_ids  = role_ids
        user.group_ids = group_ids

      # else do assignment as defined
      else

        # permission check by role
        return if !permission_check_by_role

        if params[:role_ids]
          user.role_ids = params[:role_ids]
        end
        if params[:group_ids]
          user.group_ids = params[:group_ids]
        end
      end

      # check if user already exists
      if user.email
        exists = User.where( email: user.email ).first
        if exists
          render json: { error: 'User already exists!' }, status: :unprocessable_entity
          return
        end
      end

      user.save!

      # if first user was added, set system init done
      if count <= 2
        Setting.set( 'system_init_done', true )

        # fetch org logo
        if user.email
          Service::Image.organization_suggest(user.email)
        end
      end

      # send inviteation if needed / only if session exists
      if params[:invite] && current_user

        # generate token
        token = Token.create( action: 'PasswordReset', user_id: user.id )

        # send mail
        data = {}
        data[:subject] = 'Invitation to #{config.product_name} at #{config.fqdn}'
        data[:body]    = 'Hi #{user.firstname},

        I (#{current_user.firstname} #{current_user.lastname}) invite you to #{config.product_name} - the customer support / ticket system platform.

        Click on the following link and set your password:

        #{config.http_type}://#{config.fqdn}/#password_reset_verify/#{token.name}

        Enjoy,

        #{current_user.firstname} #{current_user.lastname}

        Your #{config.product_name} Team
        '

        # prepare subject & body
        [:subject, :body].each { |key|
          data[key.to_sym] = NotificationFactory.build(
            locale: user.preferences[:locale],
            string: data[key.to_sym],
            objects: {
              token: token,
              user: user,
              current_user: current_user,
            }
          )
        }

        # send notification
        NotificationFactory.send(
          recipient: user,
          subject: data[:subject],
          body: data[:body]
        )
      end

      user_new = User.find( user.id )
      render json: user_new, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
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

    # access deny
    return if !permission_check

    user = User.find( params[:id] )

    begin

      user.update_attributes( User.param_cleanup(params) )

      # only allow Admin's and Agent's
      if role?(Z_ROLENAME_ADMIN) && role?('Agent') && params[:role_ids]
        user.role_ids = params[:role_ids]
      end

      # only allow Admin's
      if role?(Z_ROLENAME_ADMIN) && params[:group_ids]
        user.group_ids = params[:group_ids]
      end

      # only allow Admin's and Agent's
      if role?(Z_ROLENAME_ADMIN) && role?('Agent') && params[:organization_ids]
        user.organization_ids = params[:organization_ids]
      end

      # get new data
      user_new = User.find( params[:id] )
      render json: user_new, status: :ok
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
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
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(User, params)
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
  # @parameter        term            [String]        The search term.
  # @parameter        limit           [Integer]       The limit of search results.
  # @parameter        role_ids(multi) [Array<String>] A list of Role identifiers to which the Users have to be allocated to.
  # @parameter        full            [Boolean]       Defines if the result should be
  #                                                   true: { user_ids => [1,2,...], assets => {...} }
  #                                                   or false: [{:id => user.id, :label => "firstname lastname <email>", :value => "firstname lastname <email>"},...].
  #
  # @response_message 200 [Array<User>] A list of User records matching the search term.
  # @response_message 401               Invalid session.
  def search

    if role?(Z_ROLENAME_CUSTOMER) && !role?(Z_ROLENAME_ADMIN) && !role?('Agent')
      response_access_deny
      return
    end

    query_params = {
      query: params[:term],
      limit: params[:limit],
      current_user: current_user,
    }
    if params[:role_ids] && !params[:role_ids].empty?
      query_params[:role_ids] = params[:role_ids]
    end

    # do query
    user_all = User.search(query_params)

    # build result list
    if !params[:full]
      users = []
      user_all.each { |user|
        realname = user.firstname.to_s + ' ' + user.lastname.to_s
        if user.email && user.email.to_s != ''
          realname = realname + ' <' + user.email.to_s + '>'
        end
        a = { id: user.id, label: realname, value: realname }
        users.push a
      }

      # return result
      render json: users
      return
    end

    user_ids = []
    assets   = {}
    user_all.each { |user|
      assets = user.assets(assets)
      user_ids.push user.id
    }

    # return result
    render json: {
      assets: assets,
      user_ids: user_ids.uniq,
    }
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

    if role?(Z_ROLENAME_CUSTOMER) && !role?(Z_ROLENAME_ADMIN)
      response_access_deny
      return
    end

    # do query
    if params[:role_ids] && !params[:role_ids].empty?
      user_all = User.joins(:roles).where( 'roles.id' => params[:role_ids] ).where('users.id != 1').order('users.created_at DESC').limit( params[:limit] || 20 )
    else
      user_all = User.where('id != 1').order('created_at DESC').limit( params[:limit] || 20 )
    end

    # build result list
    if !params[:full]
      users = []
      user_all.each { |user|
        realname = user.firstname.to_s + ' ' + user.lastname.to_s
        if user.email && user.email.to_s != ''
          realname = realname + ' <' + user.email.to_s + '>'
        end
        a = { id: user.id, label: realname, value: realname }
        users.push a
      }

      # return result
      render json: users
      return
    end

    user_ids = []
    assets   = {}
    user_all.each { |user|
      assets = user.assets(assets)
      user_ids.push user.id
    }

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

    # permissin check
    if !role?(Z_ROLENAME_ADMIN) && !role?('Agent')
      response_access_deny
      return
    end

    # get user data
    user = User.find( params[:id] )

    # get history of user
    history = user.history_get(true)

    # return result
    render json: history
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
curl http://localhost/api/v1/users/password_reset.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"username": "some_username"}'

=end

  def password_reset_send

    # check if feature is enabled
    if !Setting.get('user_lost_password')
      render json: { error: 'Feature not enabled!' }, status: :unprocessable_entity
      return
    end

    token = User.password_reset_send( params[:username] )
    if token

      # only if system is in develop mode, send token back to browser for browser tests
      if Setting.get('developer_mode') == true
        render json: { message: 'ok', token: token.name }, status: :ok
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
curl http://localhost/api/v1/users/password_reset_verify.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"token": "SoMeToKeN", "password" "new_password"}'

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
      user = User.password_reset_via_token( params[:token], params[:password] )
    else
      user = User.password_reset_check( params[:token] )
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
curl http://localhost/api/v1/users/password_change.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"password_old": "password_old", "password_new": "password_new"}'

=end

  def password_change

    # check old password
    if !params[:password_old]
      render json: { message: 'failed', notice: ['Current password needed!'] }, status: :ok
      return
    end
    user = User.authenticate( current_user.login, params[:password_old] )
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

    user.update_attributes( password: params[:password_new] )
    render json: { message: 'ok', user_login: user.login }, status: :ok
  end

=begin

Resource:
PUT /api/v1/users/preferences.json

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
curl http://localhost/api/v1/users/preferences.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"language": "de", "notifications": true}'

=end

  def preferences
    if !current_user
      render json: { message: 'No current user!' }, status: :unprocessable_entity
      return
    end
    if params[:user]
      user = User.find(current_user.id)
      params[:user].each {|key, value|
        user.preferences[key.to_sym] = value
      }
      user.save
    end
    render json: { message: 'ok' }, status: :ok
  end

=begin

Resource:
DELETE /api/v1/users/account.json

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
curl http://localhost/api/v1/users/account.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"provider": "twitter", "uid": 581482342942}'

=end

  def account_remove
    if !current_user
      render json: { message: 'No current user!' }, status: :unprocessable_entity
      return
    end

    # provider + uid to remove
    if !params[:provider]
      render json: { message: 'provider needed!' }, status: :unprocessable_entity
      return
    end
    if !params[:uid]
      render json: { message: 'uid needed!' }, status: :unprocessable_entity
      return
    end

    # remove from database
    record = Authorization.where(
      user_id: current_user.id,
      provider: params[:provider],
      uid: params[:uid],
    )
    if !record.first
      render json: { message: 'No record found!' }, status: :unprocessable_entity
      return
    end
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

    file = Avatar.get_by_hash( params[:hash] )
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
  :message => 'ok'
}

Test:
curl http://localhost/api/v1/users/avatar -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"avatar": "base64 url"}'

=end

  def avatar_new
    return if !valid_session_with_user

    # get & validate image
    file_full   = StaticAssets.data_url_attributes( params[:avatar_full] )
    file_resize = StaticAssets.data_url_attributes( params[:avatar_resize] )

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
    current_user.update_attributes( image: avatar.store_hash )

    render json: { avatar: avatar }, status: :ok
  end

  def avatar_set_default
    return if !valid_session_with_user

    # get & validate image
    if !params[:id]
      render json: { message: 'No id of avatar!' }, status: :unprocessable_entity
      return
    end

    # set as default
    avatar = Avatar.set_default( 'User', current_user.id, params[:id] )

    # update user link
    current_user.update_attributes( image: avatar.store_hash )

    render json: {}, status: :ok
  end

  def avatar_destroy
    return if !valid_session_with_user

    # get & validate image
    if !params[:id]
      render json: { message: 'No id of avatar!' }, status: :unprocessable_entity
      return
    end

    # remove avatar
    Avatar.remove_one( 'User', current_user.id, params[:id] )

    # update user link
    avatar = Avatar.get_default( 'User', current_user.id )
    current_user.update_attributes( image: avatar.store_hash )

    render json: {}, status: :ok
  end

  def avatar_list
    return if !valid_session_with_user

    # list of avatars
    result = Avatar.list( 'User', current_user.id )
    render json: { avatars: result }, status: :ok
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

  def permission_check_by_role
    return true if role?(Z_ROLENAME_ADMIN)
    return true if role?('Agent')

    response_access_deny
    false
  end

  def permission_check
    return true if role?(Z_ROLENAME_ADMIN)
    return true if role?('Agent')

    # allow to update customer by him self
    return true if role?(Z_ROLENAME_CUSTOMER) && params[:id].to_i == current_user.id

    response_access_deny
    false
  end

end
