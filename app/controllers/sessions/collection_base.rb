# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ExtraCollection
  def session( collections, assets, user )

    # all base stuff
    collections[ Taskbar.to_app_model ] = Taskbar.where( :user_id => user.id )
    assets = {}
    collections[ Taskbar.to_app_model ].each {|item|
      assets = item.assets(assets)
    }

    collections[ Role.to_app_model ] = Role.all
    collections[ Role.to_app_model ].each {|item|
      assets = item.assets(assets)
    }

    collections[ Group.to_app_model ] = Group.all
    collections[ Group.to_app_model ].each {|item|
      assets = item.assets(assets)
    }
    if !user.is_role('Customer')
      collections[ Organization.to_app_model ]  = Organization.all
      collections[ Organization.to_app_model ].each {|item|
        assets = item.assets(assets)
      }
    else
      if user.organization_id
        collections[ Organization.to_app_model ]  = Organization.where( :id => user.organization_id )
        collections[ Organization.to_app_model ].each {|item|
          assets = item.assets(assets)
        }
      end
    end
  end
  module_function :session
end
