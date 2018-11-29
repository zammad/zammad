class MembershipStatus < ActiveRecord::Base
	belongs_to :membership, :foreign_key => [:user_id, :group_id]
end