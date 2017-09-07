require 'mixin/rails_logger'
require 'mixin/start_finish_logger'

class Sequencer
  include ::Mixin::RailsLogger
  include ::Mixin::StartFinishLogger

  attr_reader :sequence

  # Convenience wrapper for instant processing with the given attributes.
  #
  # @example
  #  Sequencer.process('Example::Sequence')
  #
  # @example
  #  Sequencer.process('Example::Sequence',
  #    parameters: {
  #      some: 'value',
  #    },
  #    expecting: [:result, :answer]
  #  )
  #
  # @return [Hash{Symbol => Object}] the final result state attributes and values
  def self.process(sequence, *args)
    new(sequence, *args).process
  end

  # Initializes a new Sequencer instance for the given Sequence with parameters and expecting result.
  #
  # @example
  #  Sequencer.new('Example::Sequence')
  #
  # @example
  #  Sequencer.new('Example::Sequence',
  #    parameters: {
  #      some: 'value',
  #    },
  #    expecting: [:result, :answer]
  #  )
  def initialize(sequence, parameters: {}, expecting: nil)
    @sequence   = Sequencer::Sequence.constantize(sequence)
    @parameters = parameters
    @expecting  = expecting

    # fall back to sequence default expecting if no explicit
    # expecting was given for this sequence
    return if !@expecting.nil?
    @expecting = @sequence.expecting
  end

  # Processes the Sequence the instance was initialized with.
  #
  # @example
  #  sequence.process
  #
  # @return [Hash{Symbol => Object}] the final result state attributes and values
  def process
    log_start_finish(:info, "Sequence '#{@sequence.name}'") do

      sequence.units.each_with_index do |unit, index|

        state.process do

          log_start_finish(:info, "Sequence '#{sequence.name}' Unit '#{unit.name}' (index: #{index})") do
            unit.process(state)
          end
        end
      end
    end

    state.to_h.tap do |result|
      logger.debug("Returning Sequence '#{@sequence.name}' result: #{result.inspect}")
    end
  end

  private

  def state
    @state ||= Sequencer::State.new(sequence,
                                    parameters: @parameters,
                                    expecting:  @expecting)
  end
end
