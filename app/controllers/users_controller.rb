# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class UsersController < ApplicationController
  before_filter :authentication_check, :except => [:create, :password_reset_send, :password_reset_verify]

=begin

Format:
JSON

Example:
{
  "id":2,
  "organization_id":null,
  "login":"m@edenhofer.de",
  "firstname":"Marti",
  "lastname":"Ede",
  "email":"m@edenhofer.de",
  "image_source":"http://www.gravatar.com/avatar/1c38b099f2344976005de69965733465?s=48",
  "web":"http://127.0.0.1",
  "password":"123",
  "phone":"112",
  "fax":"211",
  "mobile":"",
  "street":"",
  "zip":"",
  "city":"",
  "country":null,
  "verified":false,
  "active":true,
  "note":"some note",
  "source":null,
  "role_ids":[1,2],
  "group_ids":[1,2,3,4],
}

=end

=begin

Resource:
GET /api/v1/users.json

Response:
[
  {
    "id": 1,
    "login": "some_login1",
    ...
  },
  {
    "id": 2,
    "login": "some_login2",
    ...
  }
]

Test:
curl http://localhost/api/v1/users.json -v -u #{login}:#{password}

=end

  def index

    # only allow customer to fetch him self
    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      users = User.where( :id => current_user.id )
    else
      users = User.all
    end
    users_all = []
    users.each {|user|
      users_all.push User.lookup( :id => user.id ).attributes_with_associations
    }
    render :json => users_all, :status => :ok
  end

=begin

Resource:
GET /api/v1/users/1.json

Response:
{
  "id": 1,
  "login": "some_login1",
  ...
},

Test:
curl http://localhost/api/v1/users/#{id}.json -v -u #{login}:#{password}

=end

  def show

    # access deny
    return if !permission_check

    if params[:full]
      full = User.full( params[:id] )
      render :json => full
      return
    end

    user = User.find( params[:id] )
    render :json => user
  end

=begin

Resource:
POST /api/v1/users.json

Payload:
{
  "login": "some_login",
  "firstname": "some firstname",
  "lastname": "some lastname",
  "email": "some@example.com"
}

Response:
{
  "id": 1,
  "login": "some_login",
  ...
},

Test:
curl http://localhost/api/v1/users.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"login": "some_login","firstname": "some firstname","lastname": "some lastname","email": "some@example.com"}'

=end

  def create
    user = User.new( User.param_cleanup(params) )

    begin
      # check if it's first user
      count = User.all.count()

      # if it's a signup, add user to customer role
      if !current_user
        user.updated_by_id = 1
        user.created_by_id = 1

        # check if feature is enabled
        if !Setting.get('user_create_account')
          render :json => { :error => 'Feature not enabled!' }, :status => :unprocessable_entity
          return
        end

        # add first user as admin/agent and to all groups
        group_ids = []
        role_ids  = []
        if count <= 2
          Role.where( :name => [ 'Admin', 'Agent'] ).each { |role|
            role_ids.push role.id
          }
          Group.all().each { |group|
            group_ids.push group.id
          }

          # everybody else will go as customer per default
        else
          role_ids.push Role.where( :name => 'Customer' ).first.id
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
        exists = User.where( :email => user.email ).first
        if exists
          render :json => { :error => 'User already exists!' }, :status => :unprocessable_entity
          return
        end
      end

      user.save

      # if first user was added, set system init done
      if count <= 2
        Setting.set( 'system_init_done', true )
      end

      # send inviteation if needed / only if session exists
      if params[:invite] && current_user

        # generate token
        token = Token.create( :action => 'PasswordReset', :user_id => user.id )

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
            :locale  => user.locale,
            :string  => data[key.to_sym],
            :objects => {
              :token        => token,
              :user         => user,
              :current_user => current_user,
            }
          )
        }

        # send notification
        NotificationFactory.send(
          :recipient => user,
          :subject   => data[:subject],
          :body      => data[:body]
        )
      end

      user_new = User.find( user.id )
      render :json => user_new, :status => :created
    rescue Exception => e
      render :json => { :error => e.message }, :status => :unprocessable_entity
    end
  end

=begin

Resource:
PUT /api/v1/users/#{id}.json

Payload:
{
  "login": "some_login",
  "firstname": "some firstname",
  "lastname": "some lastname",
  "email": "some@example.com"
}

Response:
{
  "id": 2,
  "login": "some_login",
  ...
},

Test:
curl http://localhost/api/v1/users/2.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"login": "some_login","firstname": "some firstname","lastname": "some lastname","email": "some@example.com"}'

=end

  def update

    # access deny
    return if !permission_check

    user = User.find( params[:id] )

    begin

      user.update_attributes( User.param_cleanup(params) )

      # only allow Admin's and Agent's
      if is_role('Admin') && is_role('Agent') && params[:role_ids]
        user.role_ids = params[:role_ids]
      end

      # only allow Admin's
      if is_role('Admin') && params[:group_ids]
        user.group_ids = params[:group_ids]
      end

      # only allow Admin's and Agent's
      if is_role('Admin') && is_role('Agent') && params[:organization_ids]
        user.organization_ids = params[:organization_ids]
      end

      # get new data
      user_new = User.find( params[:id] )
      render :json => user_new, :status => :ok
    rescue Exception => e
      render :json => { :error => e.message }, :status => :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/1
  def destroy
    return if deny_if_not_role('Admin')
    model_destory_render(User, params)
  end

  # GET /api/v1/users/search
  def search

    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      response_access_deny
      return
    end

    query_params = {
      :query        => params[:term],
      :limit        => params[:limit],
      :current_user => current_user,
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
          realname = realname + ' <' +  user.email.to_s + '>'
        end
        a = { :id => user.id, :label => realname, :value => realname }
        users.push a
      }

      # return result
      render :json => users
      return
    end

    user_ids = []
    assets   = {}
    user_all.each { |user|
      assets = user.assets(assets)
      user_ids.push user.id
    }

    # return result
    render :json => {
      :assets   => assets,
      :user_ids => user_ids.uniq,
    }
  end

  # GET /api/v1/users/history/1
  def history

    # permissin check
    if !is_role('Admin') && !is_role('Agent')
      response_access_deny
      return
    end

    # get user data
    user = User.find( params[:id] )

    # get history of user
    history = user.history_get(true)

    # return result
    render :json => history
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
      render :json => { :error => 'Feature not enabled!' }, :status => :unprocessable_entity
      return
    end

    success = User.password_reset_send( params[:username] )
    if success
      render :json => { :message => 'ok' }, :status => :ok
    else
      render :json => { :message => 'failed' }, :status => :unprocessable_entity
    end
  end

=begin

Resource:
POST /api/v1/users/password_reset_verify

Payload:
{
  "token": "SoMeToKeN",
  "password" "new_password"
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
      user = User.password_reset_via_token( params[:token], params[:password] )
    else
      user = User.password_reset_check( params[:token] )
    end
    if user
      render :json => { :message => 'ok', :user_login => user.login }, :status => :ok
    else
      render :json => { :message => 'failed' }, :status => :unprocessable_entity
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
      render :json => { :message => 'Old password needed!' }, :status => :unprocessable_entity
      return
    end
    user = User.authenticate( current_user.login, params[:password_old] )
    if !user
      render :json => { :message => 'Old password is wrong!' }, :status => :unprocessable_entity
      return
    end

    # set new password
    if !params[:password_new]
      render :json => { :message => 'New password needed!' }, :status => :unprocessable_entity
      return
    end
    user.update_attributes( :password => params[:password_new] )
    render :json => { :message => 'ok', :user_login => user.login }, :status => :ok
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
      render :json => { :message => 'No current user!' }, :status => :unprocessable_entity
      return
    end
    if params[:user]
      params[:user].each {|key, value|
        current_user.preferences[key.to_sym] = value
      }
    end
    current_user.save
    render :json => { :message => 'ok' }, :status => :ok
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
      render :json => { :message => 'No current user!' }, :status => :unprocessable_entity
      return
    end

    # provider + uid to remove
    if !params[:provider]
      render :json => { :message => 'provider needed!' }, :status => :unprocessable_entity
      return
    end
    if !params[:uid]
      render :json => { :message => 'uid needed!' }, :status => :unprocessable_entity
      return
    end

    # remove from database
    record = Authorization.where(
      :user_id  => current_user.id,
      :provider => params[:provider],
      :uid      => params[:uid],
    )
    if !record.first
      render :json => { :message => 'No record found!' }, :status => :unprocessable_entity
      return
    end
    record.destroy_all
    render :json => { :message => 'ok' }, :status => :ok
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
        :filename    => file.filename,
        :type        => file.preferences['Content-Type'] || file.preferences['Mime-Type'],
        :disposition => 'inline'
      )
      return
    end

    # serve default image
    image = 'R0lGODdhMAAwAOMAAMzMzJaWlr6+vqqqqqOjo8XFxbe3t7GxsZycnAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAMAAwAAAEcxDISau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru98TwuAA+KQAQqJK8EAgBAgMEqmkzUgBIeSwWGZtR5XhSqAULACCoGCJGwlm1MGQrq9RqgB8fm4ZTUgDBIEcRR9fz6HiImKi4yNjo+QkZKTlJWWkBEAOw=='
    send_data(
      Base64.decode64(image),
      :filename    => 'image.gif',
      :type        => 'image/gif',
      :disposition => 'inline'
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
      :object           => 'User',
      :o_id             => current_user.id,
      :full             => {
        :content   => file_full[:content],
        :mime_type => file_full[:mime_type],
      },
      :resize           => {
        :content   => file_resize[:content],
        :mime_type => file_resize[:mime_type],
      },
      :source           => 'upload ' + Time.now.to_s,
      :deletable        => true,
    )

    # update user link
    current_user.update_attributes( :image => avatar.store_hash )

    render :json => { :avatar => avatar }, :status => :ok
  end

  def avatar_set_default
    return if !valid_session_with_user

    # get & validate image
    if !params[:id]
      render :json => { :message => 'No id of avatar!' }, :status => :unprocessable_entity
      return
    end

    # set as default
    avatar = Avatar.set_default( 'User', current_user.id, params[:id] )

    # update user link
    current_user.update_attributes( :image => avatar.store_hash )

    render :json => {}, :status => :ok
  end

  def avatar_destroy
    return if !valid_session_with_user

    # get & validate image
    if !params[:id]
      render :json => { :message => 'No id of avatar!' }, :status => :unprocessable_entity
      return
    end

    # remove avatar
    Avatar.remove_one( 'User', current_user.id, params[:id] )

    # update user link
    avatar = Avatar.get_default( 'User', current_user.id )
    current_user.update_attributes( :image => avatar.store_hash )

    render :json => {}, :status => :ok
  end

  def avatar_list
    return if !valid_session_with_user

    # list of avatars
    result = Avatar.list( 'User', current_user.id )
    render :json => { :avatars => result }, :status => :ok
  end

  private

  def permission_check_by_role
    return true if is_role('Admin')
    return true if is_role('Agent')

    response_access_deny
    return false
  end

  def permission_check
    return true if is_role('Admin')
    return true if is_role('Agent')

    # allow to update customer by him self
    return true if is_role('Customer') && params[:id].to_i == current_user.id

    response_access_deny
    return false
  end

end