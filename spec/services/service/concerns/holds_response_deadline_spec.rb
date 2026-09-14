# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Concerns::HoldsResponseDeadline do
  let(:deadline) { described_class::RESPONSE_DEADLINE }

  let(:service) do
    Class.new(Service::Base) do
      include Service::Concerns::HoldsResponseDeadline

      attr_reader :work

      # `Service::Base` has no initializer of its own, see `.dev/agent_docs/service_patterns.md`.
      def initialize(work:) # rubocop:disable Lint/MissingSuper
        @work = work
      end

      def execute
        with_response_deadline { work.call }
      end
    end
  end

  def elapsed
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    [(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).seconds, result]
  end

  it 'returns the value of the block' do
    _, result = elapsed { service.execute(work: -> { :done }) }

    expect(result).to be(:done)
  end

  it 'holds a fast block until the deadline' do
    duration, = elapsed { service.execute(work: -> { :done }) }

    expect(duration).to be >= deadline
  end

  it 'holds two blocks of different duration for the same time', :aggregate_failures do
    fast, = elapsed { service.execute(work: -> { :done }) }
    slow, = elapsed { service.execute(work: -> { sleep deadline / 2 }) }

    expect(fast).to be >= deadline
    expect(slow).to be >= deadline
    expect((slow - fast).abs).to be < (deadline / 2)
  end

  it 'does not extend a block which outlasts the deadline' do
    duration, = elapsed { service.execute(work: -> { sleep deadline * 2 }) }

    expect(duration).to be < (deadline * 4)
  end

  it 'holds the deadline when the block raises' do
    duration, = elapsed do
      begin
        service.execute(work: -> { raise 'nope' })
      rescue RuntimeError # rubocop:disable Lint/SuppressedException
      end
    end

    expect(duration).to be >= deadline
  end

  it 'lets the exception of the block propagate' do
    expect { service.execute(work: -> { raise 'nope' }) }.to raise_error('nope')
  end
end
