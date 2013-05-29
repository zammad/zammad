class Taskbar < ApplicationModel

store 					:state, :params
before_create   :update_time
before_update   :update_time

private
    def update_last_contact
    	self.last_contact = Time.now
  	end
end