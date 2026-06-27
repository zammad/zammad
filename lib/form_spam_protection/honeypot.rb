# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Rejects submissions where the invisible honeypot field was filled in. Real
# users never see the field; automated clients that complete every field do.
class FormSpamProtection::Honeypot
  # Namespaced so it can't collide with a real field an embedded form legitimately
  # collects (e.g. "website") and so the injected hidden field never overwrites it.
  FIELD_NAME = 'zammad_form_url'.freeze

  def verify(submission)
    # Real users never touch the hidden field, so any content at all — including
    # whitespace — flags an automated client. (blank? would let "   " through.)
    return true if submission.params[FIELD_NAME].to_s.empty?

    Rails.logger.debug 'Form spam protection: rejected submission (honeypot field was filled in).'
    false
  end
end
