class Setting < ActiveRecord::Base
  store         :options
  store         :state
  store         :state_initial
  before_create :set_initial
  after_create  :delete_cache
  after_update  :delete_cache
  after_destroy :delete_cache

  @@config = nil

  def self.load
    
    # check if config is already generated
    return @@config if @@config
    
    # read all config settings
    config = {}
    Setting.select('name, state').order(:id).each { |setting|
      config[setting.name] = setting.state[:value]
    }
    
    # config lookups
    config.each { |key, value|
      next if value.class.to_s != 'String'
      config[key].gsub!( /\#\{config\.(.+?)\}/ ) { |s|
        s = config[$1].to_s
      }
    }
    
    # store for class requests
    @@config = config
    return config
  end

  def self.get(name)
    self.load
    return @@config[name]
  end
  
  private
    def delete_cache
      @@config = nil
    end
    def set_initial
      self.state_initial = self.state
    end
end
