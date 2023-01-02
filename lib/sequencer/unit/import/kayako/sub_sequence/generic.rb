# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::SubSequence::Generic < Sequencer::Unit::Base

  uses :dry_run, :import_job, :field_map, :id_map, :default_language

  attr_accessor :iteration, :result

  EXPECTING = %i[action response].freeze

  def process
    loop.each_with_index do |_, iteration|
      @iteration = iteration
      @result = ::Sequencer.process(sequence_name,
                                    parameters: sequence_params,
                                    expecting:  self.class.const_get(:EXPECTING))
      break if iteration_should_stop?
    end
  end

  def sequence_params
    {
      request_params:   request_params,
      import_job:       import_job,
      dry_run:          dry_run,
      object:           object,
      default_language: default_language,
      field_map:        field_map,
      id_map:           id_map,
    }
  end

  def request_params
    return {} if iteration.zero?

    if cursor_pagination?
      return cursor_pagination
    end

    offset_pagination
  end

  def object
    @object ||= self.class.name.demodulize.singularize
  end

  def sequence_name
    raise NotImplementedError
  end

  private

  def offset_pagination
    {
      offset: offset,
    }
  end

  def offset
    iteration * 5 # TODO: only ddebug, normally 100
  end

  def cursor_pagination?
    return if result.nil?

    @cursor_pagination ||= result[:response].header['link'].include?('after_id')
  end

  def cursor_pagination
    {
      after_id: cursor_after_id
    }
  end

  def cursor_after_id
    unescaped_header_next_link.match(%r{after_id=(\d+)})[1]
  end

  def unescaped_header_next_link
    CGI.unescape(CGI.unescape(result[:response].header['link']))
  end

  def iteration_should_stop?
    return true if result[:action] == :failed
    return true if result[:response].header['link'].blank? || result[:response].header['link'].exclude?('rel="next"')

    false
  end
end
