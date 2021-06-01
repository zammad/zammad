# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module SequencerUnit

  def process(parameters = {}, &block)
    Sequencer::Unit.process(described_class.name, parameters, &block)
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
end
