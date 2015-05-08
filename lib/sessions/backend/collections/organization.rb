class Sessions::Backend::Collections::Organization < Sessions::Backend::Collections::Base
  model_set 'Organization'

  def load

    # get whole collection
    all = []
    if !@user.role?('Customer')
      all = Organization.all
    else
      if @user.organization_id
        all = Organization.where( id: @user.organization_id )
      end
    end

    all
  end

end
