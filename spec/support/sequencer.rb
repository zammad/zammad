module SequencerUnit

  def process(parameters, &block)
    Sequencer::Unit.process(described_class.name, parameters, &block)
  end
end

module SequencerSequence

  def process(parameters = {})
    Sequencer.process(described_class.name,
                      parameters: parameters)
  end
end

RSpec.configure do |config|
  config.include SequencerUnit, sequencer: :unit
  config.include SequencerSequence, sequencer: :sequence
end
