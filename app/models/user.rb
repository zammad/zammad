class User < ApplicationModel
  before_create           :check_name, :check_email, :check_image
  after_create            :cache_delete
  after_update            :cache_delete
  after_destroy           :cache_delete

  has_and_belongs_to_many :groups,          :after_add => :cache_update, :after_remove => :cache_update
  has_and_belongs_to_many :roles,           :after_add => :cache_update, :after_remove => :cache_update
  has_and_belongs_to_many :organizations,   :after_add => :cache_update, :after_remove => :cache_update
  has_many                :authorizations,  :after_add => :cache_update, :after_remove => :cache_update
  belongs_to              :organization,    :class_name => 'Organization'

  store                   :preferences

  def self.authenticate( username, password )
    
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
    create(
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
  
  def self.find_fulldata(user_id)

    return cache_get(user_id) if cache_get(user_id)

    # get user
    user = User.find(user_id)
    data = user.attributes

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

    groups = []
    user.groups.select('id, name').where( :active => true ).each { |group|
      groups.push group
    }
    data['groups'] = groups
    
    organization = user.organization
    data['organization'] = organization

    organizations = []
    user.organizations.select('id, name').where( :active => true ).each { |organization|
      organizations.push organization
    }
    data['organizations'] = organizations

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
end
