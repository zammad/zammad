# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

class FailingTestJob < ApplicationJob
  retry_on(StandardError, attempts: 5)

  def perform
    Rails.logger.debug 'Failing'
    raise 'Some error...'
  end
end

RSpec.describe ApplicationJob do

  it 'syncs ActiveJob#executions to Delayed::Job#attempts' do
    FailingTestJob.perform_later
    expect { Delayed::Worker.new.work_off }.to change { Delayed::Job.last.attempts }
  end
end
