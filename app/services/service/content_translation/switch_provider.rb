# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Switches a translation provider on or off. At most one provider is active: its name is stored,
# and the two flags the agent side reads follow it. All three change together or not at all, so
# nothing ever reads a provider that is half switched.
class Service::ContentTranslation::SwitchProvider < Service::Base
  attr_reader :provider, :active

  # @param provider [String] a backend name, see Service::ContentTranslation::Backend.by_name
  # @param active [Boolean] false switches the provider off, and changes nothing while another
  #   provider is the active one
  def initialize(provider:, active:)
    @provider = provider
    @active   = active
  end

  def execute
    Setting.transaction(requires_new: true) do
      # Taken before anything is written: switching on and off write the settings in opposite
      # order, so two switches at once could deadlock.
      stored_provider = Service::ContentTranslation::Backend.locked_provider_name

      active ? activate : deactivate(stored_provider)
    end
  rescue
    # A write that was rolled back is otherwise still served from the cache of this process.
    Setting.reload

    raise
  end

  private

  # Only the provider is validated. What the other writes would validate is settled by the writes
  # before them, and they would read those back from a cache that another thread may refresh in
  # between, without what is not committed yet.
  def activate
    Setting.set('content_translation_provider', provider)
    Setting.set('content_translation_service', true, validate: false)
    Setting.set('content_translation_ticket_article', true)
  end

  def deactivate(stored_provider)
    return if stored_provider != provider

    Setting.set('content_translation_service', false)
    Setting.set('content_translation_ticket_article', false)
    Setting.set('content_translation_provider', '', validate: false)
  end
end
