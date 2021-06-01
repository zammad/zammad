# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'mixin/rails_logger'
require_dependency 'mixin/start_finish_logger'

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

  # Provides the log level definition for the requested Sequencer component.
  #
  # @example
  #  Sequencer.log_level_for(:state)
  #  #=> { get: :debug, set: :debug, ... }
  #
  # @return [ActiveSupport::HashWithIndifferentAcces] the log level definition
  def self.log_level_for(component)
    Setting.get('sequencer_log_level').with_indifferent_access[component]
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
    log_start_finish(log_level[:start_finish], "Sequence '#{sequence.name}'") do

      sequence.units.each_with_index do |unit, index|

        state.process do

          log_start_finish(log_level[:unit], "Sequence '#{sequence.name}' Unit '#{unit.name}' (index: #{index})") do
            unit.process(state)
          end
        end
      end
    end

    state.to_h.tap do |result|
      logger.public_send(log_level[:result]) { "Returning Sequence '#{sequence.name}' result: #{result.inspect}" }
    end
  end

  private

  def state
    @state ||= Sequencer::State.new(sequence,
                                    parameters: @parameters,
                                    expecting:  @expecting)
  end

  def log_level
    @log_level ||= self.class.log_level_for(:sequence)
  end
end
