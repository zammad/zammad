# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Cti::Driver::Cti < Cti::Driver::Base

  def config
    Setting.get('cti_config')
  end

end
