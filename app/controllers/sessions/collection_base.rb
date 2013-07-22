# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, user )

    # all base stuff
    collections['Taskbar']       = Taskbar.where( :user_id => user.id )
    collections['Role']          = Role.all
    collections['Group']         = Group.all

    if !user.is_role('Customer')
      collections['Organization']  = Organization.all
    else
      if user.organization_id
        collections['Organization']  = Organization.where( :id => user.organization_id )
      end
    end
  end
  def push( collections, user )

    # all base stuff
    collections['Role']          = Role.all
    collections['Group']         = Group.all

    if !user.is_role('Customer')
      collections['Organization']  = Organization.all
    else
      if user.organization_id
        collections['Organization']  = Organization.where( :id => user.organization_id )
      end
    end
  end
  module_function :session, :push
end
