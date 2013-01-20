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
    users = User.all
    users_all = []
    users.each {|user|
      users_all.push User.user_data_full( user.id )
    }
    render :json => users_all
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
    user.updated_by_id = (current_user && current_user.id) || 1
    user.created_by_id = (current_user && current_user.id) || 1

    begin

      # if it's a signup, add user to customer role
      if user.created_by_id == 1

        # check if feature is enabled
        if !Setting.get('user_create_account')
          render :json => { :error => 'Feature not enabled!' }, :status => :unprocessable_entity
          return
        end

        # check if it's first user
        count     = User.all.count()
        group_ids = []
        role_ids  = []

        # add first user as admin/agent and to all groups
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
    user = User.find(params[:id])

    begin
      user.update_attributes( User.param_cleanup(params) )
      if params[:role_ids]
        user.role_ids = params[:role_ids]
      end
      if params[:group_ids]
        user.group_ids = params[:group_ids]
      end
      if params[:organization_ids]
        user.organization_ids = params[:organization_ids]
      end
      user_new = User.user_data_full( params[:id] )
      render :json => user_new, :status => :ok
    rescue Exception => e
      render :json => { :error => e.message }, :status => :unprocessable_entity
    end
  end

  # DELETE /api/users/1
  def destroy
    model_destory_render(User, params)
  end

  # GET /api/users/search
  def search

    # get params
    query = params[:term]
    limit = params[:limit] || 18

    # do query
    user_all = User.find(
      :all,
      :limit      => limit,
      :conditions => ['firstname LIKE ? or lastname LIKE ? or email LIKE ?', "%#{query}%", "%#{query}%", "%#{query}%"],
      :order      => 'firstname'
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

end
