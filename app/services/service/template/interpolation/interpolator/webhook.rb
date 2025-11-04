# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Template::Interpolation::Interpolator::Webhook < Service::Template::Interpolation::Interpolator

  # The API provides an endpoint GET /api/v1/webhook/replacements returning a
  # list of all available replacement variables lined by this method.
  def self.replacements(pre_defined_webhook_type:)
    hash = {}

    tracks.select(&:root?).each do |track|
      if custom_tracks.include?(track)
        hash.merge!(track.replacements(pre_defined_webhook_type:))
      else
        hash.merge!(track.replacements)
      end
    end

    hash
  end

  # The allowed webhook-specific track classes
  def self.custom_tracks
    [
      Service::Template::Interpolation::Interpolator::Webhook::Track::PreDefinedWebhook,
      Service::Template::Interpolation::Interpolator::Webhook::Track::Notification
    ]
  end
end
