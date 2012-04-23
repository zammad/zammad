class User < ApplicationModel
  before_create           :check_name, :check_email, :check_image
  before_update           :check_password
  after_create            :cache_delete
  after_update            :cache_delete
  after_destroy           :cache_delete

  has_and_belongs_to_many :groups,          :after_add => :cache_update, :after_remove => :cache_update
  has_and_belongs_to_many :roles,           :after_add => :cache_update, :after_remove => :cache_update
  has_and_belongs_to_many :organizations,   :after_add => :cache_update, :after_remove => :cache_update
  has_many                :tokens,          :after_add => :cache_update, :after_remove => :cache_update
  has_many                :authorizations,  :after_add => :cache_update, :after_remove => :cache_update
  belongs_to              :organization,    :class_name => 'Organization'

  store                   :preferences

  def self.authenticate( username, password )
    
    # do not authenticate with nothing
    return if !username || username == ''
    return if !password || password == '' 
    
    # try to find user based on login
    user = User.where( :login => username, :active => true ).first
    
    # try second lookup with email
    if !user
      user = User.where( :email => username, :active => true ).first
    end
    
    # no user found
    if !user
      return nil
    end
    
    # auth ok
    if user.password == password
      return user
    end

    # auth failed
    return false
  end

  def self.create_from_hash!(hash)
    url = ''
    if hash['info']['urls'] then
      url = hash['info']['urls']['Website'] || hash['info']['urls']['Twitter'] || ''
    end
    roles = Role.where( :name => 'Customer' )
    self.create(
      :login         => hash['info']['nickname'] || hash['uid'],
      :firstname     => hash['info']['name'],
      :email         => hash['info']['email'],
      :image         => hash['info']['image'],
#      :url        => url.to_s,
      :note          => hash['info']['description'],
      :source        => hash['provider'],
      :roles         => roles,
      :created_by_id => 1
    )

  end

  def self.password_reset_send(username)
    return if !username || username == ''

    # try to find user based on login
    user = User.where( :login => username, :active => true ).first
    
    # try second lookup with email
    if !user
      user = User.where( :email => username, :active => true ).first
    end

    # check if email address exists
    return if !user.email

    # generate token
    token = Token.create( :action => 'PasswordReset', :user_id => user.id )

    # send mail
    data = {}
    data[:subject] = 'Reset your #{config.product_name} password'
    data[:body]    = 'Forgot your password?

We received a request to reset the password for your #{config.product_name} account (#{user.login}).

If you want to reset your password, click on the link below (or copy and paste the URL into your browser):

#{config.http_type}://#{config.fqdn}/password_reset_verify/#{token.name}

This link takes you to a page where you can change your password.

If you don\'t want to reset your password, please ignore this message. Your password will not be reset. 

Your #{config.product_name} Team
'

    # prepare subject & body
    [:subject, :body].each { |key|
      data[key.to_sym] = NotificationFactory.build(
        :string  => data[key.to_sym],
        :objects => {
          :token => token,
          :user  => user,
        }
      )
    }

    # send notification
    NotificationFactory.send(
      :recipient => user,
      :subject   => data[:subject],
      :body      => data[:body]
    )
    return true
  end

  def self.password_reset_check(token)

    # check token
    token = Token.check( :action => 'PasswordReset', :name => token )
    return if !token
    return true
  end

  def self.password_reset_via_token(token,password)
    
    # check token
    token = Token.check( :action => 'PasswordReset', :name => token )
    return if !token
    
    # reset password
    token.user.update_attributes( :password => password )
    
    # delete token
    token.delete
    token.save
    return true
  end

  def self.find_fulldata(user_id)

    return cache_get(user_id) if cache_get(user_id)

    # get user
    user = User.find(user_id)
    data = user.attributes

    # do not show password
    user['password'] = ''

    # get linked accounts
    data['accounts'] = {}
    authorizations = user.authorizations() || []
    authorizations.each do | authorization |
      data['accounts'][authorization.provider] = {
        :uid      => authorization[:uid],
        :username => authorization[:username]
      }
    end
  
    # set roles
    roles = []
    user.roles.select('id, name').where( :active => true ).each { |role|
      roles.push role
    }
    data['roles'] = roles
    data['role_ids'] = user.role_ids

    groups = []
    user.groups.select('id, name').where( :active => true ).each { |group|
      groups.push group
    }
    data['groups'] = groups
    data['group_ids'] = user.group_ids

    organization = user.organization
    data['organization'] = organization

    organizations = []
    user.organizations.select('id, name').where( :active => true ).each { |organization|
      organizations.push organization
    }
    data['organizations'] = organizations
    data['organization_ids'] = user.organization_ids

    cache_set(user.id, data)

    return data
  end

  private
    def check_name
      if self.firstname && (!self.lastname || self.lastname == '') then
        name = self.firstname.split(' ', 2)
        self.firstname = name[0]
        self.lastname  = name[1]
      end
    end
    def check_email
      if self.email then
        self.email = self.email.downcase
      end
    end
    def check_image
      require 'digest/md5'
      if !self.image || self.image == '' then
        if self.email then
          hash = Digest::MD5.hexdigest(self.email)
          self.image = "http://www.gravatar.com/avatar/#{hash}?s=48"
        end
      end
    end
    def check_password
      
      # set old password again
      if self.password == '' || !self.password

        # get current record
        current = User.find(self.id)
        self.password = current.password
      end
    end
end
