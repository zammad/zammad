# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Interpolator < Service::Base
  include Service::Template::Interpolation::Engine::Parser
  include Service::Template::Interpolation::Engine::Validator

  attr_reader :template, :track_objects, :additional_track_generate_data

  def initialize(template:, tracks:, additional_track_generate_data: nil)
    super()

    @template = template
    @track_objects = tracks
    @additional_track_generate_data = additional_track_generate_data
  end

  def execute
    return {} if template.blank?

    # Generate all tracks
    generate_tracks(track_objects)

    variables = scan(template)
    return JSON.parse(template) if variables.blank?

    track_objects.transform_keys!(&:to_sym)
    mappings = parse(variables, track_objects)

    # NeverShouldHappen(TM)
    return JSON.parse(template) if mappings.blank?

    replace(template, mappings)

    begin
      valid!(template)
    rescue => e
      return { error: e.message }
    end

    JSON.parse(template)
  end

  # The allowed classes and methods are defined within so called track classes,
  # see files in app/services/service/template/interpolation/engine/track.
  def self.tracks
    @tracks ||= Service::Template::Interpolation::Engine::Track.descendants + custom_tracks
  end

  # Custom tracks that can be overridden by subclasses
  def self.custom_tracks
    []
  end

  private

  def generate_tracks(track_objects)
    # Generate base tracks
    self.class.tracks.select(&:root?).each do |track|
      next if !track.respond_to?(:generate)

      # Use additional data if available, otherwise use empty hash
      track.generate(track_objects, additional_track_generate_data || {})
    end
  end
end
