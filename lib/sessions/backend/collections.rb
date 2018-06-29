class Sessions::Backend::Collections < Sessions::Backend::Base

  def initialize(user, asset_lookup, client, client_id, ttl = 10)
    @user         = user
    @client       = client
    @client_id    = client_id
    @ttl          = ttl
    @asset_lookup = asset_lookup
    @backends     = backend
  end

  def push
    results = []
    @backends.each do |backend|
      #puts "B: #{backend.inspect}"
      result = backend.push
      #puts "R: #{result.inspect}"
      if result
        results.push result
      end
    end
    results
  end

  def user=(user)
    @user = user

    # update stored user in backends, too
    @backends.each do |backend|
      backend.user = user
    end
  end

  def backend

    # auto population collections
    backends = []

    # load collections to deliver from external files
    dir = File.expand_path('../../..', __dir__)
    files = Dir.glob("#{dir}/lib/sessions/backend/collections/*.rb")
    files.each do |file|
      file.gsub!("#{dir}/lib/", '')
      file.gsub!(/\.rb$/, '')
      next if file.classify == 'Sessions::Backend::Collections::Base'
      #puts "LOAD #{file.classify}---"
      #next if file == ''
      backend = file.classify.constantize.new(@user, @asset_lookup, @client, @client_id, @ttl)
      if backend
        backends.push backend
      end
    end

    backends
  end

end
