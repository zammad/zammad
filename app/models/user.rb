class User < ApplicationModel
  include Gmaps

  before_create           :check_name, :check_email, :check_login, :check_image, :check_geo
  before_update           :check_password, :check_image, :check_geo, :check_email, :check_login

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
    user = User.where( :login => username, :active => true ).first

    # try second lookup with email
    if !user
      user = User.where( :email => username, :active => true ).first
    end

    # no user found
    return nil if !user

    # development systems
    if !ENV['RAILS_ENV'] || ENV['RAILS_ENV'] == 'development'
      if password == 'test'
        return user
      end
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

    cache = self.cache_get(user_id)
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

    self.cache_set(user.id, data)

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

  # update all users geo data
  def self.geo_update_all
    User.all.each { |user|
      user.geo_update
      user.save
    }
  end

  # update geo data of one user
  def geo_update
    address = ''
    location = ['street', 'zip', 'city', 'country']
    location.each { |item|
      if self[item] && self[item] != ''
        address = address + ',' + self[item]
      end
    }

    # return if no address is given
    return if address == ''

    # dp lookup
    latlng = Gmaps.geocode(address)
    if latlng
      self.preferences['lat'] = latlng[0]
      self.preferences['lng'] = latlng[1]
    end
  end

  def update_last_login
    self.last_login = Time.now
    self.save
  end

  private
    def check_geo

      # geo update if no user exists
      if !self.id
        self.geo_update
        return
      end

      location = ['street', 'zip', 'city', 'country']

      # get current user data      
      current = User.where( :id => self.id ).first
      return if !current

      # check if geo update is needed
      current_location = {}
      location.each { |item|
        current_location[item] = current[item]
      }

      # get full address
      next_location = {}
      location.each { |item|
        next_location[item] = self[item]
      }

      # return if address hasn't changed and geo data is already available
      return if ( current_location == next_location ) && ( self.preferences['lat'] && self.preferences['lng'] )

      # geo update
      self.geo_update
    end

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

      # set old password again
      if self.password == '' || !self.password

        # get current record
        current = User.find(self.id)
        self.password = current.password
      end
    end
end
