class Authorization < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id, :uid, :provider
  validates_uniqueness_of :uid, :scope => :provider
  
  def self.find_from_hash(hash)
    auth = Authorization.where( :provider => hash['provider'], :uid => hash['uid'] )
    if auth && auth.first then
#      raise auth.first.to_yaml
#      raise hash.to_yaml

      # update auth tokens
      auth.first.update_attributes(
        :token    => hash['credentials']['token'],
        :secret   => hash['credentials']['secret']
      )
      
      # update image if needed
      if hash['info']['image']
        user = User.where( :id => auth.first.user_id ).first
        user.update_attributes(
          :image    => hash['info']['image']
        )
      end
    end

    return auth.first
  end
  
  def self.create_from_hash(hash, user = nil)
    if user then
      user.update_attributes(
        :username => hash['username'],
        :image    => hash['info']['image']
      )
    else
      user = User.create_from_hash!(hash)    
    end
    Authorization.create(
      :user     => user,
      :uid      => hash['uid'],
      :username => hash['username'],
      :provider => hash['provider'],
      :token    => hash['credentials']['token'],
      :secret   => hash['credentials']['secret']
    )
  end

end