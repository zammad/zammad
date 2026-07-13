# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Authorization::Provider::MicrosoftOffice365 < Authorization::Provider
  private

  def find_user
    return if info['email'].nil?

    return if !email_verified?

    User.find_by(email: info['email'].downcase)
  end

  # In multi-tenant (/common) setups any Azure user worldwide could present an
  # arbitrary email address. Microsoft signals whether the email is verified on
  # the owning domain via the "xms_edov" claim in the ID token.  The claim is
  # extracted via OmniAuth::Strategies::MicrosoftOffice365Database#extra and
  # stored under extra.id_token_claims.xms_edov.
  #
  # "xms_edov" is an optional claim that only appears once an admin has
  # explicitly configured it on the app registration - and in testing, Azure
  # only ever seems to send it as true (verified) or omit it, never send an
  # explicit false for an unverified domain. So by default its absence must
  # not change existing behaviour (no claim at all is treated the same as no
  # check ever existed), and only an explicit negative claim blocks linking.
  #
  # Admins who have configured the "email" and "xms_edov" optional claims on
  # the app registration can opt into strict, fail-closed enforcement via the
  # "require_verified_email_domain" field on auth_microsoft_office365_credentials
  # - once enabled, only an explicit "true" is accepted; a missing claim (the
  # common case in the wild, per the above) blocks linking instead of allowing it.
  def email_verified?
    xms_edov = auth_hash.dig('extra', 'id_token_claims', 'xms_edov')
    return truthy?(xms_edov) if strict_email_verification?
    return true if xms_edov.nil?

    truthy?(xms_edov)
  end

  def strict_email_verification?
    truthy?(Setting.get('auth_microsoft_office365_credentials')&.dig('require_verified_email_domain'))
  end
end
