module KnowledgeBasePublicPageTitleHelper
  def kb_public_page_title(leading, trailing, exception)
    [
      leading&.translation&.title,
      kb_public_page_title_suffix(trailing, exception)
    ].compact.join(' - ')
  end

  def kb_public_page_title_suffix(item, exception)
    return item&.translation&.title if exception.blank?

    suffix = case exception
             when :not_found
               'Not Found'
             when :alternatives
               'Alternative Translations'
             end

    zt(suffix)
  end
end
