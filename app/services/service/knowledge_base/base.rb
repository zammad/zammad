# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared plumbing of the knowledge base write services.
class Service::KnowledgeBase::Base < Service::Base
  private

  # The knowledge base every write goes to: the single one the system supports, and only while it is
  #   active. Editing an inactive one is not this stack's job — activating it and changing its
  #   settings (not its texts) is the legacy admin dialog, which works on the record directly. The
  #   browse queries resolve it the same way, so nothing here writes to a knowledge base that cannot
  #   be read back.
  #
  # Raises rather than returning nil, so a caller never writes half of something into a knowledge
  #   base that is not there to be edited.
  def active_knowledge_base!
    @active_knowledge_base ||= ::KnowledgeBase.active.first!
  end

  # The locale the submitted texts belong to, and the one the caller renders its response in.
  #   Resolved from what was passed as `kb_locale`: the KnowledgeBase::Locale record, or the system
  #   locale code (`de-de`) for callers that have no lookup of their own.
  def kb_locale
    @kb_locale ||= resolve_kb_locale!
  end

  # A record is taken as given — whoever resolved it knows which locale they mean. A code is looked
  #   up strictly, unlike the browsing queries which fall back to the user's preferred locale:
  #   writing texts into another locale than the caller named is not the same as rendering them in
  #   it — the caller would have no way to tell where the texts ended up.
  def resolve_kb_locale!
    case @submitted_kb_locale
    when ::KnowledgeBase::Locale
      @submitted_kb_locale
    else
      active_knowledge_base!.kb_locales.joins(:system_locale).find_by(locales: { locale: @submitted_kb_locale }) ||
        raise(Exceptions::UnprocessableContent, __('The selected language does not belong to this knowledge base.'))
    end
  end
end
