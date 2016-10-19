# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Network < ApplicationModel
  #  belongs_to :group
  #  belongs_to :state,    :class_name => 'Ticket::State'
  #  belongs_to :priority, :class_name => 'Ticket::Priority'

  class Category < ApplicationModel
    self.table_name = 'network_categories'

    class Type < ApplicationModel
    end

    class Subscription < ApplicationModel
    end
  end

  class Item < ApplicationModel
    class Comment < ApplicationModel
    end

    class Plus < ApplicationModel
      self.table_name = 'network_item_plus'
    end

    class Subscription < ApplicationModel
    end
  end

  class Privacy < ApplicationModel
    self.table_name = 'network_privacies'
  end
end
