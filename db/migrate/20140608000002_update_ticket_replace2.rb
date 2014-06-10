class UpdateTicketReplace2 < ActiveRecord::Migration
  def up
    Overview.destroy_all
UserInfo.current_user_id = 1
overview_role = Role.where( :name => 'Agent' ).first
Overview.create_if_not_exists(
  :name       => 'My assigned Tickets',
  :link       => 'my_assigned',
  :prio       => 1000,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [ 1,2,3 ],
    'tickets.owner_id' => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'Unassigned & Open Tickets',
  :link       => 'all_unassigned',
  :prio       => 1001,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [1,2,3],
    'tickets.owner_id' => 1,
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'All Open Tickets',
  :link       => 'all_open',
  :prio       => 1002,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [1,2,3],
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'Escalated Tickets',
  :link       => 'all_escalated',
  :prio       => 1010,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.escalation_time' =>{ 'direction' => 'before', 'count'=> 5, 'area' => 'minute' },
  },
  :order => {
    :by        => 'escalation_time',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'group', 'owner', 'escalation_time' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'owner', 'escalation_time' ],
    :m => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'owner', 'escalation_time' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'My pending reached Tickets',
  :link       => 'my_pending_reached',
  :prio       => 1020,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [3],
    'tickets.owner_id' => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'All Tickets',
  :link       => 'all',
  :prio       => 9003,
  :role_id    => overview_role.id,
  :condition  => {
#      'tickets.state_id' => [3],
#      'tickets.owner_id'        => current_user.id,
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :s => [ 'title', 'customer', 'state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'state', 'priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

overview_role = Role.where( :name => 'Customer' ).first
Overview.create_if_not_exists(
  :name       => 'My Tickets',
  :link       => 'my_tickets',
  :prio       => 1000,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [ 1,2,3,4,6 ],
    'tickets.customer_id'     => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'created_at' ],
    :s => [ 'number', 'title', 'state', 'priority', 'created_at' ],
    :m => [ 'number', 'title', 'state', 'priority', 'created_at' ],
    :view_mode_default => 's',
  },
)
Overview.create_if_not_exists(
  :name                => 'My Organization Tickets',
  :link                => 'my_organization_tickets',
  :prio                => 1100,
  :role_id             => overview_role.id,
  :organization_shared => true,
  :condition => {
    'tickets.state_id' => [ 1,2,3,4,6 ],
    'tickets.organization_id' => 'current_user.organization_id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'priority', 'created_at' ],
    :m => [ 'number', 'title', 'state', 'priority', 'created_at' ],
    :view_mode_default => 's',
  },
)

  end

  def down
  end
end
