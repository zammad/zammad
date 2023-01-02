# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      __('Not Found')
    when :alternatives
      __('Alternative Translations')
    end
  end
end
