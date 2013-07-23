# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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
  "image":"http://www.gravatar.com/avatar/1c38b099f2344976005de69965733465?s=48",
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
GET /api/users.json

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
curl http://localhost/api/users.json -v -u #{login}:#{password}

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
      users_all.push User.user_data_full( user.id )
    }
    render :json => users_all, :status => :ok
  end

=begin

Resource:
GET /api/users/1.json

Response:
{
  "id": 1,
  "login": "some_login1",
  ...
},

Test:
curl http://localhost/api/users/#{id}.json -v -u #{login}:#{password}

=end

  def show

    # access deny
    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      if params[:id].to_i != current_user.id
        response_access_deny
        return
      end
    end
    user = User.user_data_full( params[:id] )
    render :json => user
  end

=begin

Resource:
POST /api/users.json

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
curl http://localhost/api/users.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"login": "some_login","firstname": "some firstname","lastname": "some lastname","email": "some@example.com"}'

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

      # if first user set init done
      if count <= 2
        Setting.create_or_update(
          :title       => 'System Init Done',
          :name        => 'system_init_done',
          :area        => 'Core',
          :description => 'Defines if application is in init mode.',
          :options     => {},
          :state       => true,
          :frontend    => true
        )
      end

      # send inviteation if needed / only if session exists
      if params[:invite] && current_user

        # generate token
        token = Token.create( :action => 'PasswordReset', :user_id => user.id )

        # send mail
        data = {}
        data[:subject] = 'Invitation to #{config.product_name} at #{config.fqdn}'
        data[:body]    = 'Hi #{user.firstname},

        I (#{current_user.firstname} #{current_user.lastname}) invite you to #{config.product_name} - a customer support / ticket system platform.

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

      user_new = User.user_data_full( user.id )
      render :json => user_new, :status => :created
    rescue Exception => e
      render :json => { :error => e.message }, :status => :unprocessable_entity
    end
  end

=begin

Resource:
PUT /api/users/#{id}.json

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
curl http://localhost/api/users/2.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"login": "some_login","firstname": "some firstname","lastname": "some lastname","email": "some@example.com"}'

=end

  def update

    # allow user to update him self
    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      if params[:id] != current_user.id
        response_access_deny
        return
      end
    end

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
      user_new = User.user_data_full( params[:id] )
      render :json => user_new, :status => :ok
    rescue Exception => e
      render :json => { :error => e.message }, :status => :unprocessable_entity
    end
  end

  # DELETE /api/users/1
  def destroy
    return if deny_if_not_role('Admin')
    model_destory_render(User, params)
  end

  # GET /api/users/search
  def search

    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      response_access_deny
      return
    end

    # do query
    user_all = User.search(
      :query        => params[:term],
      :limit        => params[:limit],
      :current_user => current_user,
    )

    # build result list
    users = []
    user_all.each do |user|
      realname = user.firstname.to_s + ' ' + user.lastname.to_s
      if user.email && user.email.to_s != ''
        realname = realname + ' <' +  user.email.to_s + '>'
      end
      a = { :id => user.id, :label => realname, :value => realname }
      users.push a
    end

    # return result
    render :json => users
  end

=begin

Resource:
POST /api/users/password_reset

Payload:
{
  "username": "some user name"
}

Response:
{
  :message => 'ok'
}

Test:
curl http://localhost/api/users/password_reset.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"username": "some_username"}'

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
POST /api/users/password_reset_verify

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
curl http://localhost/api/users/password_reset_verify.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"token": "SoMeToKeN", "password" "new_password"}'

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
POST /api/users/password_change

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
curl http://localhost/api/users/password_change.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"password_old": "password_old", "password_new": "password_new"}'

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
PUT /api/users/preferences.json

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
curl http://localhost/api/users/preferences.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"language": "de", "notifications": true}'

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
DELETE /api/users/account.json

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
curl http://localhost/api/users/account.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"provider": "twitter", "uid": 581482342942}'

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

end
