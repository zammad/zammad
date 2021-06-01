# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CtiController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  # list current caller log
  # GET /api/v1/cti/log
  def index
    backends = [
      {
        name:    'CTI (generic)',
        enabled: Setting.get('cti_integration'),
        url:     '#system/integration/cti',
      },
      {
        name:    'sipgate.io',
        enabled: Setting.get('sipgate_integration'),
        url:     '#system/integration/sipgate',
      },
      {
        name:    'Placetel',
        enabled: Setting.get('placetel_integration'),
        url:     '#system/integration/placetel',
      }
    ]

    result = Cti::Log.log(current_user)
    result[:backends] = backends
    render json: result
  end

  # set caller log to done
  # POST /api/v1/cti/done/:id
  def done
    log = Cti::Log.find(params['id'])
    log.done = params['done']
    log.save!
    render json: {}
  end

  # sets for all given ids the caller log to done
  # POST /api/v1/cti/done/bulk
  def done_bulk

    log_ids = params['ids'] || []
    log_ids.each do |log_id|
      log = Cti::Log.find(log_id)
      log.done = true
      log.save!
    end
    render json: {}
  end

end
