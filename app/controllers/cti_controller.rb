# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class CtiController < ApplicationController
  before_action :authentication_check

  # list current caller log
  def index
    deny_if_not_role('CTI')

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
    deny_if_not_role('CTI')
    log = Cti::Log.find(params['id'])
    log.done = params['done']
    log.save
    render json: {}
  end

end
