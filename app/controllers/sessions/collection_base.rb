# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, user )

    # all base stuff
    collections[ Taskbar.to_app_model ]       = Taskbar.where( :user_id => user.id )
    collections[ Role.to_app_model ]          = Role.all
    collections[ Group.to_app_model ]         = Group.all

    if !user.is_role('Customer')
      collections[ Organization.to_app_model ]  = Organization.all
    else
      if user.organization_id
        collections[ Organization.to_app_model ]  = Organization.where( :id => user.organization_id )
      end
    end
  end
  def push( collections, user )

    # all base stuff
    #collections[ Role.to_app_model ]          = Role.all
    #collections[ Group.to_app_model ]         = Group.all

    #if !user.is_role('Customer')
    #  collections[ Organization.to_app_model ]  = Organization.all
    #else
    #  if user.organization_id
    #    collections[ Organization.to_app_model ]  = Organization.where( :id => user.organization_id )
    #  end
    #end
  end
  module_function :session, :push
end
