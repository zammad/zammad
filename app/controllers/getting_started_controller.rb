class GettingStartedController < ApplicationController

  def index

    # check if first user already exists
    master_user = 0
    count = User.all.count()
    if count == 1
      master_user = 1
    end

    # get all groups
    @groups = Group.where( :active => true )
    @roles  = Role.where( :active => true )

    # return result
    respond_to do |format|
      format.json {
        render :json => {
          :master_user => master_user,
          :groups      => @groups,
          :roles       => @roles,
        }
      }
    end
  end

end