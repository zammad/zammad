module ExtraCollection
  def session( collections, user )

    # all base stuff
    collections['Role']          = Role.all
    collections['Group']         = Group.all
    collections['Organization']  = Organization.all

  end
  def push( collections, user )

    # all base stuff
    collections['Role']          = Role.all
    collections['Group']         = Group.all
    collections['Organization']  = Organization.all

  end
  module_function :session, :push
end