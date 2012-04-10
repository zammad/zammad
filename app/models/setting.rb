class Setting < ActiveRecord::Base
  store     :options
  store     :state
  store     :state_initial
  before_create :set_initial

  @@config = nil

  def self.load
    return @@config if @@config
    config = {}
    Setting.select('name, state').order(:id).each { |setting|
      config[setting.name] = setting.state[:value]
    }
    @@config = config
    return config
  end

  def self.get(name)
    self.load
    return @@config[name]
  end
  
  private
    def set_initial
      self.state_initial = self.state
    end
end
