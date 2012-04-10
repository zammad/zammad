class Network < ActiveRecord::Base
#  belongs_to :group
#  belongs_to :ticket_state, :class_name => 'Ticket::State'
#  belongs_to :ticket_priority, :class_name => 'Ticket::Priority'

  class Category < ActiveRecord::Base
    self.table_name = 'network_categories'

    class Type < ActiveRecord::Base
    end

    class Subscription < ActiveRecord::Base
    end
  end
  
  class Item < ActiveRecord::Base
    class Comment < ActiveRecord::Base
    end

    class Plus < ActiveRecord::Base
      self.table_name = 'network_item_plus'
    end

    class Subscription < ActiveRecord::Base
    end
  end

  class Privacy < ActiveRecord::Base
    self.table_name = 'network_privacies'
  end
end
