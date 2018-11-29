class Membership < ActiveRecord::Base
  self.primary_keys = :user_id, :group_id
  belongs_to :user
	belongs_to :group
	has_many :statuses, :class_name => 'MembershipStatus', :foreign_key => [:user_id, :group_id]
  has_many :readings, :primary_key => :user_id, :foreign_key => :user_id
end