# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Store::File < ApplicationModel
  include ApplicationLib
  after_destroy     :destroy_provider

  # add new file
  def self.add(data)
    sha = Digest::SHA256.hexdigest( data )

    file = Store::File.where( :sha => sha ).first
    if file == nil

      # load backend based on config
      adapter_name = Setting.get('storage_provider') || 'DB'
      if !adapter_name
        raise "Missing storage_provider setting option"
      end
      adapter = self.load_adapter( "Store::Provider::#{ adapter_name }" )
      adapter.add( data, sha )
      file = Store::File.create(
        :provider => adapter_name,
        :sha      => sha,
      )
    end
    file
  end

  # read content
  def content
    adapter = self.class.load_adapter("Store::Provider::#{ self.provider }")
    if self.sha
      c = adapter.get( self.sha )
    else
      # fallback until migration is done
      c = Store::Provider::DB.where( :md5 => self.md5 ).first.data
    end
    c
  end

  # check data and sha, in case fix it
  def self.verify(fix_it = nil)
    success = true
    Store::File.all.each {|item|
      content = item.content
      sha = Digest::SHA256.hexdigest( content )
      puts "CHECK: Store::File.find(#{item.id}) "
      if sha != item.sha
        success = false
        puts "DIFF: sha diff of Store::File.find(#{item.id}) "
        if fix_it
          item.update_attribute( :sha, sha )
        end
      end
    }
    success
  end

  # move file from one to other provider
  # e. g. Store::File.move('File', 'DB')
  # e. g. Store::File.move('DB', 'File')
  def self.move(source, target)
    adapter_source = load_adapter("Store::Provider::#{ source }")
    adapter_target = load_adapter("Store::Provider::#{ target }")

    Store::File.all.each {|item|
      next if item.provider == target
      content = item.content

      # add to new provider
      adapter_target.add( content, item.sha )

      # update meta data
      item.update_attribute( :provider, target )

      # remove from old provider
      adapter_source.delete( item.sha )

      puts "NOTICE: Moved file #{item.sha} from #{source} to #{target}"
    }
    true
  end

  private

  def destroy_provider
    adapter = self.class.load_adapter("Store::Provider::#{ self.provider }")
    adapter.delete( self.sha )
  end
end