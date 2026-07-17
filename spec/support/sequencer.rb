# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module SequencerUnit

  def process(parameters = {}, &)
    Sequencer::Unit.process(described_class.name, parameters, &)
  end
end

module SequencerSequence

  def process(parameters = {})
    Sequencer.process(described_class.name,
                      parameters: parameters)
  end
end

module SequencerCaller

  def expect_sequence(sequence_name = nil)

    expected_method_call = receive(:process)
    if sequence_name
      expected_method_call.with(sequence_name)
    end

    expect(Sequencer).to expected_method_call
  end

  def expect_no_sequence(sequence_name = nil)

    expected_method_call = receive(:process)
    if sequence_name
      expected_method_call.with(sequence_name)
    end

    expect(Sequencer).not_to expected_method_call
  end
end

RSpec.configure do |config|
  config.include SequencerUnit, sequencer: :unit
  config.include SequencerSequence, sequencer: :sequence
  config.include SequencerCaller, sequencer: :caller

  # Sequencer::Unit::Import::Common::ImportJob::Statistics::Store persists progress to
  #   import_job every 10 real seconds. These sequence specs build_stubbed their import_job
  #   (DB access forbidden), so a slow-running sequence under CI load can cross that threshold
  #   and crash on the resulting #save! call. Freezing time to prevent this instead broke
  #   attachment-ordering assertions elsewhere, because Store.list orders by created_at and
  #   multiple attachments saved within the same frozen instant become unorderable ties - so
  #   disable the periodic-save check directly instead of touching the clock.
  config.before(:each, sequencer: :sequence) do
    allow_any_instance_of(Sequencer::Unit::Import::Common::ImportJob::Statistics::Store).to receive(:store?).and_return(false)
  end
end
