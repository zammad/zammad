# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# EmailAddress gem reports email addresses starting with + as invalid.
# However, email addresses starting with + are quite common.
# For example as phone numbers which start + in international format.
#
# There is a PR to fix this issue in EmailAddress gem
# However, it is not merged for months
# https://github.com/afair/email_address/pull/93
#
# This monkeypatch shall be removed once above PR is merged
# and EmailAddress gem is updated.

module EmailAddressValidator
  class Local
    def parse_tag(raw)
      separator = @config[:tag_separator] ||= '+'

      return raw if raw.start_with? separator

      raw.split(separator, 2)
    end
  end
end
