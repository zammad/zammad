module ExtraCollection
  def session( collections, user )

    # all base stuff
    collections['Taskbar']       = Taskbar.where( :user_id => user.id )
    collections['Role']          = Role.all
    collections['Group']         = Group.all

    if !user.is_role('Customer')
      collections['Organization']  = Organization.all
    end
  end
  def push( collections, user )

    # all base stuff
    collections['Role']          = Role.all
    collections['Group']         = Group.all

    if !user.is_role('Customer')
      collections['Organization']  = Organization.all
    end
  end
  module_function :session, :push
end
