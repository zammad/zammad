class Sessions::Backend::Collections::Organization < Sessions::Backend::Collections::Base
  model_set 'Organization'

  def load

    # check timeout
    cache = Sessions::CacheIn.get( self.collection_key )
    return cache if @last_change && cache

    # update last changed
    if !@user.is_role('Customer')
      last = self.class.model.constantize.select('updated_at').order('updated_at DESC').first
      if last
        @last_change = last.updated_at
      end
    else
      if @user.organization_id
        last = Organization.where( :id => @user.organization_id ).first
        @last_change = last.updated_at
      end
    end

    # if no entry exists, remember last check
    if !@last_change
      @last_change = Time.now
    end

    # get whole collection
    all = []
    if !@user.is_role('Customer')
      all = Organization.all
    else
      if @user.organization_id
        all = Organization.where( :id => @user.organization_id )
      end
    end

    # set new timeout
    Sessions::CacheIn.set( self.collection_key, all, { :expires_in => 10.minutes } )

    all
  end

  def changed?

    # if no data has been delivered till now
    return true if !@last_change

    # check if update has been done
    if !@user.is_role('Customer')
      last = self.class.model.constantize.select('updated_at').order('updated_at DESC').first
    else
      if @user.organization_id
        last = Organization.where( :id => @user.organization_id ).first
      end
    end
    return false if !last
    return false if last.updated_at == @last_change

    # delete collection cache
    Sessions::CacheIn.delete( self.collection_key )

    # collection has changed
    true
  end

end