# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Extends the 'net/ldap' class Net::LDAP::Entry
# without overwriting methods.
class Net::LDAP::Entry

  # Creates a duplicate of the internal Hash containing the
  # attributes of the entry.
  #
  # @see Net::LDAP::Entry#initialize
  # @see Net::LDAP::Entry#attribute_names
  #
  # @example get the Hash
  #   entry.to_h
  #   #=> {dn: ['...'], another_attribute: ['...', ...], ...}
  #
  # @return [Hash{Symbol=>Array<String>}] A duplicate of the internal Hash with the entries attributes.
  def to_h
    @myhash.dup
  end
end
