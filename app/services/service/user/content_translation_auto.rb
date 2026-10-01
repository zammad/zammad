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
    # A preference nobody may act on must not be storable either - the interface hides the switch
    # from the same answer.
    Service::ContentTranslation::TicketArticle::CheckAutoAllowed.execute(user: current_user)

    current_user.preferences['content_translation_auto'] = enabled
    current_user.save!
  end
end
