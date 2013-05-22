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
      :conditions => ['name LIKE ? OR note LIKE ?', "%#{query}%", "%#{query}%"],
      :order      => 'name'
    )

    # if only a few organizations are found, search for names of users
    if organizations.length <= 3
      organizations = Organization.select('DISTINCT(organizations.id)').joins('LEFT OUTER JOIN users ON users.organization_id = organizations.id').find(
        :all,
        :limit      => limit,
        :conditions => ['users.firstname LIKE ? or users.lastname LIKE ? or users.email LIKE ?', "%#{query}%", "%#{query}%", "%#{query}%"],
        :order      => 'organizations.name'
      ) 
    end
    return organizations
  end

end
