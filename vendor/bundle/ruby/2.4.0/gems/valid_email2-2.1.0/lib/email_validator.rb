# This is a shim for keeping backwards compatibility.
# See the discussion in: https://github.com/lisinge/valid_email2/pull/79
class EmailValidator < ValidEmail2::EmailValidator
  def validate_each(record, attribute, value)
    warn "DEPRECATION WARNING: The email validator from valid_email2 has been " +
         "deprecated in favour of using the namespaced 'valid_email_2/email' validator. " +
         "For more information see https://github.com/lisinge/valid_email2#upgrading-to-v200"
    super
  end
end
