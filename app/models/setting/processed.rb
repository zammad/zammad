# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Setting::Processed
  include ::Mixin::HasBackends

  def self.process_settings!(input)
    backends.each do |backend|
      backend.new(input).process_settings!
    end

    input
  end

  def self.process_frontend_settings!(input)
    backends.each do |backend|
      backend.new(input).process_frontend_settings!
    end

    input
  end
end
