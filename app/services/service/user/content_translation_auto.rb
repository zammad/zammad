# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Remembers whether the current user reads whole tickets in their target language. It is a personal
#   preference: switching it in one ticket switches it everywhere, and every ticket opened
#   afterwards is translated at once.
class Service::User::ContentTranslationAuto < Service::Base
  requires_current_user!

  attr_reader :enabled

  def initialize(enabled:)
    @enabled = enabled
  end

  def execute
    ensure_allowed!

    current_user.preferences['content_translation_auto'] = enabled
    current_user.save!
  end

  private

  # A preference nobody may act on must not be storable either - the interface hides the switch
  # from the same answer.
  def ensure_allowed!
    return if Service::ContentTranslation::TicketArticle::AutoAllowed.execute(user: current_user)

    raise Exceptions::Forbidden, __('Automatic translation of ticket articles is not available for you.')
  end
end
