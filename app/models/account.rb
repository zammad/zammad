module Account
  class Outbound < ActiveRecord::Base
    self.table_name = 'account_outbound'
  end

  class Inbound < ActiveRecord::Base
    self.table_name = 'account_inbound'
  end
  
  class InboundFilter < ActiveRecord::Base
    self.table_name = 'account_inbound_filter'
  end

end