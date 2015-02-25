class Sessions::Backend::Collections

  def initialize( user, client, client_id )
    @user      = user
    @client    = client
    @client_id = client_id
    @backends  = self.backend
  end


  def push
    results = []
    @backends.each {|backend|
      #puts "B: #{backend.inspect}"
      result = backend.push
      #puts "R: #{result.inspect}"
      if result
        results.push result
      end
    }
    results
  end

  def backend

    # auto population collections
    backends = []

    # load collections to deliver from external files
    dir = File.expand_path('../../../../', __FILE__)
    files = Dir.glob( "#{dir}/lib/sessions/backend/collections/*.rb" )
    for file in files
      file.gsub!("#{dir}/lib/", '')
      file.gsub!(/\.rb$/, '')
      next if file.classify == 'Sessions::Backend::Collections::Base'
      #puts "LOAD #{file.classify}---"
      #next if file == ''
      backend = file.classify.constantize.new(@user, @client, @client_id)
      if backend
        backends.push backend
      end
    end

    backends
  end

end