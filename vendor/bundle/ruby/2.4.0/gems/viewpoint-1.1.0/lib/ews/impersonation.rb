module Viewpoint::EWS

  ConnectingSID = {
    :UPN => 'PrincipalName',
    :SID => 'SID',
    :PSMTP => 'PrimarySmtpAddress',
    :SMTP => 'SmtpAddress'
  }

  # @param connecting_type [String] should be one of the ConnectingSID variables
  #   ConnectingSID[:UPN] - use User Principal Name method
  #   ConnectingSID[:SID] - use Security Identifier method
  #   ConnectingSID[:PSMTP] - use primary Simple Mail Transfer Protocol method
  #   ConnectingSID[:SMTP] - use Simple Mail Transfer Protocol method
  #   you can add any other string, it will be converted into xml tag on soap request
  # @param address [String] an address to include to requests for impersonation
  def set_impersonation(connecting_type, address)
    if ConnectingSID.has_value? connecting_type or connecting_type.is_a? String then
      ews.impersonation_type = connecting_type
      ews.impersonation_address = address
    else
      raise EwsBadArgumentError, "Not a proper connecting method: #{connecting_type.class}"
    end
  end

  def remove_impersonation
    ews.impersonation_type = ""
    ews.impersonation_address = ""
  end
end