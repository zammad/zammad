# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, assets, user )

    # all ticket stuff
    collections[ Ticket::StateType.to_app_model ]       = Ticket::StateType.all
    collections[ Ticket::StateType.to_app_model ].each {|item|
      assets = item.assets(assets)
    }
    collections[ Ticket::State.to_app_model ]           = Ticket::State.all
    collections[ Ticket::State.to_app_model ].each {|item|
      assets = item.assets(assets)
    }
    collections[ Ticket::Priority.to_app_model ]        = Ticket::Priority.all
    collections[ Ticket::Priority.to_app_model ].each {|item|
      assets = item.assets(assets)
    }
    collections[ Ticket::Article::Type.to_app_model ]   = Ticket::Article::Type.all
    collections[ Ticket::Article::Type.to_app_model ].each {|item|
      assets = item.assets(assets)
    }
    collections[ Ticket::Article::Sender.to_app_model ] = Ticket::Article::Sender.all
    collections[ Ticket::Article::Sender.to_app_model ].each {|item|
      assets = item.assets(assets)
    }
    if !user.is_role('Customer')

      # all signatures
      collections[ Signature.to_app_model ]     = Signature.all
      collections[ Signature.to_app_model ].each {|item|
        assets = item.assets(assets)
      }

      # all email addresses
      collections[ EmailAddress.to_app_model ]  = EmailAddress.all
      collections[ EmailAddress.to_app_model ].each {|item|
        assets = item.assets(assets)
      }
    end
  end
  module_function :session
end