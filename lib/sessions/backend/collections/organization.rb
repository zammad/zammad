class Sessions::Backend::Collections::Organization < Sessions::Backend::Collections::Base
  model_set 'Organization'

  def load

    # get whole collection
    all = []

    if @user.organization_id
      all = Organization.lookup(id: @user.organization_id)
    end

    all
  end

end
