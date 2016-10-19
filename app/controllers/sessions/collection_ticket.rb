# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, assets, user )

    # all ticket stuff
    collections[ Macro.to_app_model ] = []
    Macro.all.each { |item|
      assets = item.assets(assets)
    }
    collections[ Ticket::StateType.to_app_model ] = []
    Ticket::StateType.all.each { |item|
      assets = item.assets(assets)
    }
    collections[ Ticket::State.to_app_model ] = []
    Ticket::State.all.each { |item|
      assets = item.assets(assets)
    }
    collections[ Ticket::Priority.to_app_model ] = []
    Ticket::Priority.all.each { |item|
      assets = item.assets(assets)
    }
    collections[ Ticket::Article::Type.to_app_model ] = []
    Ticket::Article::Type.all.each { |item|
      assets = item.assets(assets)
    }
    collections[ Ticket::Article::Sender.to_app_model ] = []
    Ticket::Article::Sender.all.each { |item|
      assets = item.assets(assets)
    }
    if user.permissions?(['ticket.agent', 'admin.channel_email'])

      # all signatures
      collections[ Signature.to_app_model ] = []
      Signature.all.each { |item|
        assets = item.assets(assets)
      }

      # all email addresses
      collections[ EmailAddress.to_app_model ] = []
      EmailAddress.all.each { |item|
        assets = item.assets(assets)
      }
    end
    [collections, assets]
  end
  module_function :session
end
