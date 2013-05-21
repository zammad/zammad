class Organization < ApplicationModel
  has_and_belongs_to_many :users
  validates               :name, :presence => true

  def self.search(params)

    # get params
    query = params[:query]
    limit = params[:limit] || 10
    current_user = params[:current_user]

    # enable search only for agents and admins
    return [] if !current_user.is_role('Agent') && !current_user.is_role('Admin')

    # do query
    organizations = Organization.find(
      :all,
      :limit      => limit,
      :conditions => ['name LIKE ?', "%#{query}%"],
      :order      => 'name'
    )
    return organizations
  end

end
