# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'digest/sha2'
require 'organization'

class User < ApplicationModel
  before_create   :check_name, :check_email, :check_login, :check_image, :check_password
  before_update   :check_password, :check_image, :check_email, :check_login_update
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_destroy   :notify_clients_after_destroy

  has_and_belongs_to_many :groups,          :after_add => :cache_update, :after_remove => :cache_update
  has_and_belongs_to_many :roles,           :after_add => :cache_update, :after_remove => :cache_update
  has_and_belongs_to_many :organizations,   :after_add => :cache_update, :after_remove => :cache_update
  has_many                :tokens,          :after_add => :cache_update, :after_remove => :cache_update
  has_many                :authorizations,  :after_add => :cache_update, :after_remove => :cache_update
  belongs_to              :organization,    :class_name => 'Organization'

  store                   :preferences

  def fullname
    fullname = ''
    if self.firstname
      fullname = fullname + self.firstname
    end
    if self.lastname
      if fullname != ''
        fullname = fullname + ' '
      end
      fullname = fullname + self.lastname
    end
    return fullname
  end

  def is_role( role_name )
    self.roles.each { |role|
      return role if role.name == role_name
    }
    return false
  end

  def self.authenticate( username, password )

    # do not authenticate with nothing
    return if !username || username == ''
    return if !password || password == ''

    # try to find user based on login
    user = User.where( :login => username.downcase, :active => true ).first

    # try second lookup with email
    if !user
      user = User.where( :email => username.downcase, :active => true ).first
    end

    # check failed logins
    max_login_failed = Setting.get('password_max_login_failed') || 10
    if user && user.login_failed > max_login_failed
      return false
    end

    # use auth backends
    config = [
      {
        :adapter => 'internal',
      },
      {
        :adapter => 'test',
      },
    ]
    Setting.where( :area => 'Security::Authentication' ).each {|setting|
      if setting.state[:value]
        config.push setting.state[:value]
      end
    }

    # try to login against configure auth backends
    user_auth = nil
    config.each {|config_item|
      next if !config_item[:adapter]
      next if config_item.class == TrueClass
      file = "auth/#{config_item[:adapter]}"
      require file
      user_auth = Auth.const_get("#{config_item[:adapter].to_s.upcase}").check( username, password, config_item, user )

      # auth ok
      if user_auth

        # remember last login date
        user_auth.update_last_login

        # reset login failed
        user_auth.login_failed = 0
        user_auth.save

        return user_auth
      end
    }

    # set login failed +1
    if !user_auth && user
      user.login_failed = user.login_failed + 1
      user.save
    end

    # auth failed
    sleep 1
    return user_auth
  end

  def self.sso(params)

    # use auth backends
    config = [
      {
        :adapter => 'env',
      },
      {
        :adapter => 'otrs',
      },
    ]
    #    Setting.where( :area => 'Security::Authentication' ).each {|setting|
    #      if setting.state[:value]
    #        config.push setting.state[:value]
    #      end
    #    }

    # try to login against configure auth backends
    user_auth = nil
    config.each {|config_item|
      next if !config_item[:adapter]
      next if config_item.class == TrueClass
      file = "sso/#{config_item[:adapter]}"
      require file
      user_auth = SSO.const_get("#{config_item[:adapter].to_s.upcase}").check( params, config_item )

      # auth ok
      if user_auth

        # remember last login date
        user_auth.update_last_login

        # reset login failed
        user_auth.login_failed = 0
        user_auth.save

        return user_auth
      end
    }

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
      :updated_by_id => 1,
      :created_by_id => 1,
    )

  end

  def self.password_reset_send(username)
    return if !username || username == ''

    # try to find user based on login
    user = User.where( :login => username.downcase, :active => true ).first

    # try second lookup with email
    if !user
      user = User.where( :email => username.downcase, :active => true ).first
    end

    # check if email address exists
    return if !user
    return if !user.email

    # generate token
    token = Token.create( :action => 'PasswordReset', :user_id => user.id )

    # send mail
    data = {}
    data[:subject] = 'Reset your #{config.product_name} password'
    data[:body]    = 'Forgot your password?

    We received a request to reset the password for your #{config.product_name} account (#{user.login}).

    If you want to reset your password, click on the link below (or copy and paste the URL into your browser):

    #{config.http_type}://#{config.fqdn}/#password_reset_verify/#{token.name}

    This link takes you to a page where you can change your password.

    If you don\'t want to reset your password, please ignore this message. Your password will not be reset.

    Your #{config.product_name} Team
    '

    # prepare subject & body
    [:subject, :body].each { |key|
      data[key.to_sym] = NotificationFactory.build(
        :locale    => user.locale,
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

  # check token
  def self.password_reset_check(token)
    user = Token.check( :action => 'PasswordReset', :name => token )

    # reset login failed if token is valid
    if user
      user.login_failed = 0
      user.save
    end
    return user
  end

  def self.password_reset_via_token(token,password)

    # check token
    user = Token.check( :action => 'PasswordReset', :name => token )
    return if !user

    # reset password
    user.update_attributes( :password => password )

    # delete token
    Token.where( :action => 'PasswordReset', :name => token ).first.destroy
    return user
  end

  def self.search(params)

    # get params
    query = params[:query]
    limit = params[:limit] || 10
    current_user = params[:current_user]

    # enable search only for agents and admins
    return [] if !current_user.is_role('Agent') && !current_user.is_role('Admin')

    # do query
    users = User.find(
      :all,
      :limit      => limit,
      :conditions => ['(firstname LIKE ? or lastname LIKE ? or email LIKE ?) AND id != 1', "%#{query}%", "%#{query}%", "%#{query}%"],
      :order      => 'firstname'
    )
    return users
  end

  def self.find_fulldata(user_id)

    cache = self.cache_get(user_id, true)
    return cache if cache

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
      roles.push role.attributes
    }
    data['roles'] = roles
    data['role_ids'] = user.role_ids

    groups = []
    user.groups.select('id, name').where( :active => true ).each { |group|
      groups.push group.attributes
    }
    data['groups'] = groups
    data['group_ids'] = user.group_ids

    organization = user.organization
    if organization
      data['organization'] = organization.attributes
    end

    organizations = []
    user.organizations.select('id, name').where( :active => true ).each { |organization|
      organizations.push organization.attributes
    }
    data['organizations'] = organizations
    data['organization_ids'] = user.organization_ids

    self.cache_set(user.id, data, true)

    return data
  end

  def self.user_data_full (user_id)

    # get user
    user = User.find_fulldata(user_id)

    # do not show password
    user['password'] = ''

    # TEMP: compat. reasons
    user['preferences'] = {} if user['preferences'] == nil

    items = []
    if user['preferences'][:tickets_open].to_i > 0
      item = {
        :url   => '',
        :name  => 'open',
        :count => user['preferences'][:tickets_open] || 0,
        :title => 'Open Tickets',
        :class => 'user-tickets',
        :data  => 'open'
      }
      items.push item
    end
    if user['preferences'][:tickets_closed].to_i > 0
      item = {
        :url   => '',
        :name  => 'closed',
        :count => user['preferences'][:tickets_closed] || 0,
        :title => 'Closed Tickets',
        :class => 'user-tickets',
        :data  => 'closed'
      }
      items.push item
    end

    # show linked topics and items
    if items.count > 0
      topic = {
        :title => 'Tickets',
        :items => items,
      }
      user['links'] = []
      user['links'].push topic
    end

    return user
  end

  def update_last_login
    self.last_login = Time.now
    self.save
  end

  private

  def check_name

    if ( self.firstname && !self.firstname.empty? ) && ( !self.lastname || self.lastname.empty? )

      # Lastname, Firstname
      scan = self.firstname.scan(/, /)
      if scan[0]
        name = self.firstname.split(', ', 2)
        self.lastname  = name[0]
        self.firstname = name[1]
        return
      end

      # Firstname Lastname
      name = self.firstname.split(' ', 2)
      self.firstname = name[0]
      self.lastname  = name[1]
      return

      # -no name- firstname.lastname@example.com
    elsif ( !self.firstname || self.firstname.empty? ) && ( !self.lastname || self.lastname.empty? ) && ( self.email && !self.email.empty? )
      scan = self.email.scan(/^(.+?)\.(.+?)\@.+?$/)
      if scan[0]
        self.firstname = scan[0][0].capitalize
        self.lastname  = scan[0][1].capitalize
      end

    end
  end

  def check_email
    if self.email
      self.email = self.email.downcase
    end
  end

  def check_login
    if self.login
      self.login = self.login.downcase
      check = true
      while check
        exists = User.where( :login => self.login ).first
        if exists
          self.login = self.login + rand(99).to_s
        else
          check = false
        end
      end
    end
  end

  # FIXME: Remove me later
  def check_login_update
    if self.login
      self.login = self.login.downcase
    end
  end

  def check_image
    require 'digest/md5'
    if !self.image || self.image == ''
      if self.email
        hash = Digest::MD5.hexdigest(self.email)
        self.image = "http://www.gravatar.com/avatar/#{hash}?s=48"
      end
    end
  end

  def check_password

    # set old password again if not given
    if self.password == '' || !self.password

      # get current record
      if self.id
        current = User.find(self.id)
        self.password = current.password
      end

      # create crypted password if not already crypted
    else
      if self.password !~ /^\{sha2\}/
        crypted = Digest::SHA2.hexdigest( self.password )
        self.password = "{sha2}#{crypted}"
      end
    end
  end
end
