# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Cti::Driver::Cti < Cti::Driver::Base

  def config
    Setting.get('cti_config')
  end

end
