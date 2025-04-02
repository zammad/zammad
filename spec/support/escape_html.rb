# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module EscapeHtmlHelper
  # From now on, CGI#escapeHTML escapes single quotes `'` as `&#39;`, in addition to other supported HTML entities.
  #   This may cause some problems with existing implementations of HTML escaping, in case they do not use
  #   CGI#escapeHTML internally or conform to the established OWASP standard. Therefore, we bring back the old
  #   behavior in form of a helper function, so we can reliably compare actual values with expected ones.
  #   https://bugs.ruby-lang.org/issues/5485
  def escape_html_wo_single_quotes(string)
    single_quote_char = "\u0027" # apostrophe/single quotation mark
    replacement_char  = "\uFFFD" # replacement character
    target_string = string.gsub(single_quote_char, replacement_char)
    target_string = CGI.escapeHTML(target_string)
    target_string.gsub(replacement_char, single_quote_char)
  end
end

RSpec.configure do |config|
  config.include EscapeHtmlHelper
end
