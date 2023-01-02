# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Contacts::Blocked < Sequencer::Unit::Import::Freshdesk::Contacts::Default

  def request_params
    super.merge(
      state: 'blocked',
    )
  end

end
