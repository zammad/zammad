module ExtraCollection
  def add(collections)

    # all base stuff
    collections['Role']          = Role.all
    collections['Group']         = Group.all
    collections['Organization']  = Organization.all

  end
  module_function :add
end