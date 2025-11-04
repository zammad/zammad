# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Interpolator::AIAgent < Service::Template::Interpolation::Interpolator
  # The allowed webhook-specific track classes
  def self.custom_tracks
    [
      Service::Template::Interpolation::Interpolator::AIAgent::Track::AIAgentResult,
    ]
  end
end
