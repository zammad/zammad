# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, user )

    collections[ Network.to_app_model ]                 = Network.all
    collections[ Network::Category.to_app_model ]       = Network::Category.all
    collections[ Network::Category::Type.to_app_model ] = Network::Category::Type.all
    collections[ Network::Privacy.to_app_model ]        = Network::Privacy.all

  end
  def push( collections, user )

    collections[ Network.to_app_model ]                 = Network.all
    collections[ Network::Category.to_app_model ]       = Network::Category.all
    collections[ Network::Category::Type.to_app_model ] = Network::Category::Type.all
    collections[ Network::Privacy.to_app_model ]        = Network::Privacy.all

  end
  module_function :session, :push
end
