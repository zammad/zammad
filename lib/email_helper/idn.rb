# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class EmailHelper::Idn

  def self.to_ascii(address)
    if address =~ %r{@([^>\s]+)}
      address.sub!($1, SimpleIDN.to_ascii($1))
    end
    address
  end

  def self.to_unicode(address)
    if address =~ %r{@([\w.-]+)}
      address.sub!($1, SimpleIDN.to_unicode($1))
    end
    address
  end

end
