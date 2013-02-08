class Authorization < ApplicationModel
  belongs_to              :user
  validates_presence_of   :user_id, :uid, :provider
  validates_uniqueness_of :uid,     :scope => :provider
  
  def self.find_from_hash(hash)
    auth = Authorization.where( :provider => hash['provider'], :uid => hash['uid'] ).first
    if auth

      # update auth tokens
      auth.update_attributes(
        :token    => hash['credentials']['token'],
        :secret   => hash['credentials']['secret']
      )

      # update username of auth entry if empty
      if !auth.username && hash['info']['nickname']
        auth.update_attributes(
          :username    => hash['info']['nickname'],
        )
      end

      # update image if needed
      if hash['info']['image']
        user = User.find( auth.user_id )
        user.update_attributes(
          :image => hash['info']['image']
        )
      end
    end
    return auth
  end
  
  def self.create_from_hash(hash, user = nil)
    if user then
      user.update_attributes(
#        :username => hash['username'],
        :image => hash['info']['image']
      )

      # fillup empty attributes
      # TODO
      
    else
      user = User.create_from_hash!(hash)    
    end

    auth = Authorization.create(
      :user     => user,
      :uid      => hash['uid'],
      :username => hash['info']['nickname'] || hash['username'],
      :provider => hash['provider'],
      :token    => hash['credentials']['token'],
      :secret   => hash['credentials']['secret']
    )
    return auth
  end
end