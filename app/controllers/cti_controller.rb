# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class CtiController < ApplicationController
  prepend_before_action { authentication_check(permission: 'cti.agent') }

  # list current caller log
  def index
    backends = [
      {
        name: 'sipgate.io',
        enabled: Setting.get('sipgate_integration'),
        url: '#system/integration/sipgate',
      }
    ]

    result = Cti::Log.log
    result[:backends] = backends
    render json: result
  end

  # set caller log to done
  def done
    log = Cti::Log.find(params['id'])
    log.done = params['done']
    log.save
    render json: {}
  end

end
