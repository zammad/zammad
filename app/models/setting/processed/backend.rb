# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Setting::Processed::Backend
  def initialize(input)
    @input = input
  end

  def process_settings!; end
end
