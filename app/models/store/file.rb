# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store::File < ApplicationModel
  include ApplicationLib
  after_destroy     :destroy_provider

  # add new file
  def self.add(data)
    md5 = Digest::MD5.hexdigest( data )
    file = Store::File.where( :md5 => md5 ).first
    if file == nil

      # load backend based on config
      adapter_name = Setting.get('storage_provider') || 'DB'
      if !adapter_name
        raise "Missing storage_provider setting option"
      end
      adapter = self.load_adapter( "Store::Provider::#{ adapter_name }" )
      adapter.add( data, md5 )
      file = Store::File.create(
        :provider => adapter_name,
        :md5      => md5,
      )
    end
    file
  end

  # read content
  def content
    puts "get #{self.id} #{self.provider}"
    adapter = self.class.load_adapter("Store::Provider::#{ self.provider }")
    adapter.get( self.md5 )
  end


  # check data and md5, in case fix it
  def self.check_md5(fix_it = nil)
    success = true
    Store::File.all.each {|item|
      content = item.content
      md5 = Digest::MD5.hexdigest( content )
      puts "CHECK: Store::File.find(#{item.id}) "
      if md5 != item.md5
        success = false
        puts "DIFF: md5 diff of Store::File.find(#{item.id}) "
        if fix_it
          item.update_attribute( :md5, md5 )
        end
      end
    }
    success
  end

  # move file from one to other provider
  def self.move(source, target)
    adapter_source = load_adapter("Store::Provider::#{ source }")
    adapter_target = load_adapter("Store::Provider::#{ target }")

    Store::File.all.each {|item|
      next if item.provider == target
      content = item.content

      # add to new provider
      adapter_target.add( content, item.md5 )

      # update meta data
      item.update_attribute( :provider, target )

      # remove from old provider
      adapter_source.delete( item.md5 )

      puts "NOTICE: Moved file #{item.md5} from #{source} to #{target}"
    }
  end

  private

  def destroy_provider
    adapter = self.class.load_adapter("Store::Provider::#{ self.provider }")
    adapter.delete( md5 )
  end
end