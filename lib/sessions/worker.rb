class Sessions::Worker
  def initialize( user_id )
    @user_id = user_id
    @data = {}
    @cache_key = 'user_' + user_id.to_s
    self.log 'notify', "---user started user state"

    Sessions::CacheIn.set( 'last_run_' + user_id.to_s , true, { :expires_in => 20.seconds } )

    user = User.find( @user_id )
    return if !user

    self.fetch( user )
  end

  def fetch(user)

    while true

      # check if user is still with min one open connection
      if !Sessions::CacheIn.get( 'last_run_' + user.id.to_s )
        self.log 'notify', "---user - closeing thread - no open user connection"
        return
      end

      self.log 'notice', "---user - fetch user data"
      # overview
      Sessions::Backend::TicketOverviewIndex.worker( user, self )

      # overview lists
      Sessions::Backend::TicketOverviewList.worker( user, self )

      # create_attributes
      Sessions::Backend::TicketCreate.worker( user, self )

      # recent viewed
      Sessions::Backend::RecentViewed.worker( user, self )

      # activity steam
      Sessions::Backend::ActivityStream.worker( user, self )

      # rss
      Sessions::Backend::Rss.worker( user, self )

      # auto population of default collections
      Sessions::Backend::Collections.worker( user, self )

      self.log 'notice', "---/user-"
      sleep 1
    end
  end

  def log( level, data )
    return if level == 'notice'
    puts "#{Time.now}:user_id(#{ @user_id }) #{ data }"
  end
end

