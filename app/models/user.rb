class User < ActiveRecord::Base
  before_create :check_name, :check_email, :check_image
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :organizations
  belongs_to :organization,               :class_name => 'Organization'
  has_many :authorizations

  def self.authenticate(username, password)
    user = User.where( :login => username, :active => true ).first
    return nil if user.nil?
    logger.debug 'auth'
    logger.debug username
    logger.debug user.login
    logger.debug password
    logger.debug user.password
    logger.debug user.inspect
#    return user
    return user if user.password == password
    return
  end

  def self.create_from_hash!(hash)
#    logger.debug(hash.inspect)
#    raise hash.to_yaml  
#    exit
    url = ''
    if hash['info']['urls'] then
      url = hash['info']['urls']['Website'] || hash['info']['urls']['Twitter'] || ''
    end
#    logger.debug(hash['info'].inspect)
#    raise url.to_yaml
#    exit
#    logger.debug('aaaaaaaa')
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
