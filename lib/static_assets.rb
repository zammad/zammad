module StaticAssets

  def self.data_url_attributes( data_url )
    data = {}
    if data_url =~ /^data:(.+?);base64,(.+?)$/
      data[:content_type] = $1
      data[:content]      = Base64.decode64($2)
      return data
    end
    raise "Unable to parse data url: #{data_url.substr(0,100)}"
  end

  # store image 1:1
  def self.store_raw( content, content_type )
    Store.remove( :object => 'System::Logo', :o_id => 1 )
    Store.add(
      :object      => 'System::Logo',
      :o_id        => 1,
      :data        => content,
      :filename    => 'image',
      :preferences => {
        'Content-Type' => content_type
      },
    )
    Digest::MD5.hexdigest( content )
  end

  # read raw 1:1
  def self.read_raw
    list = Store.list( :object => 'System::Logo', :o_id => 1 )
    if list && list[0]
      return Store.find( list[0] )
    end
    raise "No such raw logo!"
  end

  # store image in right size
  def self.store( content, content_type )
    Store.remove( :object => 'System::Logo', :o_id => 2 )
    Store.add(
      :object      => 'System::Logo',
      :o_id        => 2,
      :data        => content,
      :filename    => 'image',
      :preferences => {
        'Content-Type' => content_type
      },
    )
    StaticAssets.sync
    Digest::MD5.hexdigest( content )
  end

  # read image
  def self.read

    # use reduced dimensions
    list = Store.list( :object => 'System::Logo', :o_id => 2 )

    # as fallback use 1:1
    if !list || !list[0]
      list = Store.list( :object => 'System::Logo', :o_id => 1 )
    end

    # store hash in config
    if list && list[0]
      file = Store.find( list[0] )
      hash = Digest::MD5.hexdigest( file.content )
      Setting.set('product_logo', hash)
      return file
    end
  end

  # sync image to fs
  def self.sync
    file = read
    return if !file

    hash = Digest::MD5.hexdigest( file.content )
    path = "#{Rails.root.to_s}/public/assets/images/#{hash}"
    File.open( path, 'wb' ) do |f|
      f.puts file.content
    end
  end
end