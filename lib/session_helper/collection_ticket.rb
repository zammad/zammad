# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SessionHelper::CollectionTicket

  module_function

  def session(collections, assets, user)

    # all ticket stuff
    collections[ Ticket::StateType.to_app_model ] = []
    Ticket::StateType.all.each do |item|
      assets = item.assets(assets)
    end
    collections[ Ticket::State.to_app_model ] = []
    Ticket::State.all.each do |item|
      assets = item.assets(assets)
    end
    collections[ Ticket::Priority.to_app_model ] = []
    Ticket::Priority.all.each do |item|
      assets = item.assets(assets)
    end
    collections[ Ticket::Article::Type.to_app_model ] = []
    Ticket::Article::Type.all.each do |item|
      assets = item.assets(assets)
    end
    collections[ Ticket::Article::Sender.to_app_model ] = []
    Ticket::Article::Sender.all.each do |item|
      assets = item.assets(assets)
    end

    collections[ Ticket::TimeAccounting::Type.to_app_model ] = []
    Ticket::TimeAccounting::Type.all.each do |item|
      assets = item.assets(assets)
    end

    if user.permissions?(['ticket.agent', 'admin.channel_email'])
      collections[ TextModule.to_app_model ] = []
      TextModulePolicy::Scope.new(user, TextModule).resolve.each do |item|
        assets = item.assets(assets)
      end

      [
        Macro,
        Signature,
        EmailAddress,
        Template,
        Ticket::SharedDraftStart,
      ].each do |klass|
        collections[ klass.to_app_model ] = []
        klass.all.each do |item|
          assets = item.assets(assets)
        end
      end
    end
    [collections, assets]
  end
end
