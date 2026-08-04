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
  # Strict mode additionally requires the "email" claim to match the address that
  # is about to be linked, see #claim_email_verified? below.
  def email_verified?
    xms_edov = id_token_claims['xms_edov']

    return truthy?(xms_edov) && claim_email_verified? if strict_email_verification?
    return true if xms_edov.nil?

    truthy?(xms_edov)
  end

  # "xms_edov" only vouches for the ID token's own "email" claim, while the address
  # that is actually linked comes from the Graph "/me" response
  # (OmniAuth::Strategies::MicrosoftOffice365 builds info.email from the tenant's
  # "mail"/"userPrincipalName" attribute). Both are controlled by the signing-in
  # tenant and can differ, so a verified claim address must not be mistaken for
  # verification of a *different* address - otherwise strict mode could be satisfied
  # with a genuinely verified claim email while linking to somebody else's account.
  #
  # This is only enforced in strict mode: there, the "email" optional claim is a
  # documented prerequisite, so requiring it is safe. In default mode the claim is
  # usually absent, and treating that as "no signal" (i.e. link, as before) is the
  # deliberate non-breaking behaviour described above.
  def claim_email_verified?
    claim_email = id_token_claims['email']
    return false if claim_email.blank?

    claim_email.to_s.casecmp?(info['email'].to_s)
  end

  def id_token_claims
    auth_hash.dig('extra', 'id_token_claims') || {}
  end

  def strict_email_verification?
    truthy?(Setting.get('auth_microsoft_office365_credentials')&.dig('require_verified_email_domain'))
  end
end
