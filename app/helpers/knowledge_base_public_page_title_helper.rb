# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module KnowledgeBasePublicPageTitleHelper
  def kb_public_page_title(leading, trailing, exception)
    [
      leading&.translation&.title,
      kb_public_page_title_suffix(trailing, exception)
    ].compact.join(' - ')
  end

  def kb_public_page_title_suffix(item, exception)
    case item
    when HasTranslations
      return item&.translation&.title if exception.blank?

      zt kb_public_page_title_suffix_exception(exception)
    when String
      item
    end
  end

  def kb_public_page_title_suffix_exception(exception)
    case exception
    when :not_found
      'Not Found'
    when :alternatives
      'Alternative Translations'
    end
  end
end
