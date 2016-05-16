class Sessions::Backend::Collections::Organization < Sessions::Backend::Collections::Base
  model_set 'Organization'

  def load

    # get whole collection
    all = []

    if @user.organization_id
      organization = Organization.lookup(id: @user.organization_id)
      if organization
        all = [organization]
      end
    end

    all
  end

end
