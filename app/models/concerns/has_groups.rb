# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasGroups
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_group_relations

    attr_accessor :group_access_buffer

    after_save :process_group_access_buffer

    # add association to Group, too but ignore it in asset output
    Group.has_many group_through_identifier
    Group.has_many model_name.collection.to_sym, through: group_through_identifier, after_add: :cache_update, after_remove: :cache_update, dependent: :destroy
    Group.association_attributes_ignored group_through_identifier

    association_attributes_ignored :groups, group_through_identifier

    has_many group_through_identifier
    has_many :groups, through: group_through_identifier do

      # A helper to join the :through table into the result of groups to access :through attributes
      #
      # @param [String, Array<String>] access Limiting to one or more access verbs. 'full' gets added automatically
      #
      # @example All access groups
      #   user.groups.access
      #   #=> [#<Group id: 1, access="read", ...>, ...]
      #
      # @example Groups for given access(es) plus 'full'
      #   user.groups.access('read')
      #   #=> [#<Group id: 1, access="full", ...>, ...]
      #
      # @example Groups for given access(es)es plus 'full'
      #   user.groups.access('read', 'change')
      #   #=> [#<Group id: 1, access="full", ...>, ...]
      #
      # @return [ActiveRecord::AssociationRelation<[<Group]>] List of Groups with :through attributes
      def access(*access)
        table_name = proxy_association.owner.class.group_through.table_name
        query      = select("#{ActiveRecord::Base.connection.quote_table_name('groups')}.*, #{ActiveRecord::Base.connection.quote_table_name(table_name)}.*")
        return query if access.blank?

        access.push('full') if access.exclude?('full')

        query.where("#{table_name}.access" => access)
      end
    end
  end

  # Checks a given Group( ID) for given access(es) for the instance.
  # Checks indirect access via Roles if instance has Roles, too.
  #
  # @example Group ID param
  #   user.group_access?(1, 'read')
  #   #=> true
  #
  # @example Group param
  #   user.group_access?(group, 'read')
  #   #=> true
  #
  # @example Access list
  #   user.group_access?(group, ['read', 'create'])
  #   #=> true
  #
  # @return [Boolean]
  def group_access?(group_id, access)
    return false if !active?
    return false if !groups_access_permission?

    group_id = self.class.ensure_group_id_parameter(group_id)
    access   = self.class.ensure_group_access_list_parameter(access)

    # check direct access
    return true if group_through.klass.eager_load(:group).exists?(
      group_through.foreign_key => id,
      group_id: group_id,
      access: access,
      groups: {
        active: true
      }
    )

    # check indirect access through Roles if possible
    return false if !respond_to?(:role_access?)

    role_access?(group_id, access)
  end

  # Lists the Group IDs the instance has the given access(es) plus 'full' to.
  # Adds indirect accessable Group IDs via Roles if instance has Roles, too.
  #
  # @example Single access
  #   user.group_ids_access('read')
  #   #=> [1, 3, ...]
  #
  # @example Access list
  #   user.group_ids_access(['read', 'create'])
  #   #=> [1, 3, ...]
  #
  # @return [Array<Integer>] Group IDs the instance has the given access(es) to.
  def group_ids_access(access)
    return [] if !active?
    return [] if !groups_access_permission?

    access      = self.class.ensure_group_access_list_parameter(access)
    foreign_key = group_through.foreign_key
    klass       = group_through.klass

    # check direct access
    ids   = klass.eager_load(:group).where(foreign_key => id, access: access, groups: { active: true }).pluck(:group_id)
    ids ||= []

    # check indirect access through roles if possible
    return ids if !respond_to?(:role_ids)

    role_group_ids = RoleGroup.eager_load(:group).where(role_id: role_ids, access: access, groups: { active: true }).pluck(:group_id)

    # combines and removes duplicates
    # and returns them in one statement
    ids | role_group_ids
  end

  # Lists Groups the instance has the given access(es) plus 'full' to.
  # Adds indirect accessable Groups via Roles if instance has Roles, too.
  #
  # @example Single access
  #   user.groups_access('read')
  #   #=> [#<Group id: 1, access="read", ...>, ...]
  #
  # @example Access list
  #   user.groups_access(['read', 'create'])
  #   #=> [#<Group id: 1, access="read", ...>, ...]
  #
  # @return [Array<Group>] Groups the instance has the given access(es) to.
  def groups_access(access)
    group_ids = group_ids_access(access)
    Group.where(id: group_ids)
  end

  # Returns a map of Group name to access
  #
  # @example
  #   user.group_names_access_map
  #   #=> {'Users' => 'full', 'Support' => ['read', 'change']}
  #
  # @return [Hash<String=>String,Array<String>>] The map of Group name to access
  def group_names_access_map
    groups_access_map(:name)
  end

  # Stores a map of Group ID to access. Deletes all other relations.
  #
  # @example
  #   user.group_names_access_map = {'Users' => 'full', 'Support' => ['read', 'change']}
  #   #=> {'Users' => 'full', 'Support' => ['read', 'change']}
  #
  # @return [Hash<String=>String,Array<String>>] The given map
  def group_names_access_map=(name_access_map)
    groups_access_map_store(name_access_map) do |group_name|
      Group.where(name: group_name).pluck(:id).first
    end
  end

  # Returns a map of Group ID to access
  #
  # @example
  #   user.group_ids_access_map
  #   #=> {1 => 'full', 42 => ['read', 'change']}
  #
  # @return [Hash<Integer=>String,Array<String>>] The map of Group ID to access
  def group_ids_access_map
    groups_access_map(:id)
  end

  # Stores a map of Group ID to access. Deletes all other relations.
  #
  # @example
  #   user.group_ids_access_map = {1 => 'full', 42 => ['read', 'change']}
  #   #=> {1 => 'full', 42 => ['read', 'change']}
  #
  # @return [Hash<Integer=>String,Array<String>>] The given map
  def group_ids_access_map=(id_access_map)
    groups_access_map_store(id_access_map)
  end

  # An alias to .groups class method
  def group_through
    @group_through ||= self.class.group_through
  end

  # Checks if the instance has general permission to Group access.
  #
  # @example
  #   customer_user.groups_access_permission?
  #   #=> false
  #
  # @return [Boolean]
  def groups_access_permission?
    return true if !respond_to?(:permissions?)

    permissions?('ticket.agent')
  end

  private

  def groups_access_map(key)
    return {} if !active?
    return {} if !groups_access_permission?

    groups.access.where(active: true).pluck(key, :access).each_with_object({}) do |entry, hash|
      hash[ entry[0] ] ||= []
      hash[ entry[0] ].push(entry[1])
    end
  end

  def groups_access_map_store(map)
    fill_group_access_buffer do
      Hash(map).each do |group_identifier, accesses|
        # use given key as identifier or look it up
        # via the given block which returns the identifier
        group_id = block_given? ? yield(group_identifier) : group_identifier

        Array(accesses).each do |access|
          push_group_access_buffer(
            group_id: group_id,
            access:   access
          )
        end
      end
    end
  end

  def fill_group_access_buffer
    @group_access_buffer = []
    yield
    process_group_access_buffer if id
  end

  def push_group_access_buffer(entry)
    @group_access_buffer.push(entry)
  end

  def flush_group_access_buffer
    # group_access_buffer is at least an empty Array
    # if changes to the map were performed
    # otherwise it's just an update of other attributes
    return if group_access_buffer.nil?

    yield
    self.group_access_buffer = nil
    cache_delete
    push_ticket_create_screen_background_job
  end

  def process_group_access_buffer

    flush_group_access_buffer do
      destroy_group_relations

      break if group_access_buffer.blank?

      foreign_key = group_through.foreign_key
      entries     = group_access_buffer.collect do |entry|
        entry[foreign_key] = id
        entry
      end

      group_through.klass.create!(entries)
    end

    true
  end

  def destroy_group_relations
    group_through.klass.where(group_through.foreign_key => id).destroy_all
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    # Lists IDs of instances having the given access(es) to the given Group.
    #
    # @example Group ID param
    #   User.group_access_ids(1, 'read')
    #   #=> [1, 3, ...]
    #
    # @example Group param
    #   User.group_access_ids(group, 'read')
    #   #=> [1, 3, ...]
    #
    # @example Access list
    #   User.group_access_ids(group, ['read', 'create'])
    #   #=> [1, 3, ...]
    #
    # @return [Array<Integer>]
    def group_access_ids(group_id, access)
      group_access(group_id, access).collect(&:id)
    end

    # Lists instances having the given access(es) to the given Group.
    #
    # @example Group ID param
    #   User.group_access(1, 'read')
    #   #=> [#<User id: 1, ...>, ...]
    #
    # @example Group param
    #   User.group_access(group, 'read')
    #   #=> [#<User id: 1, ...>, ...]
    #
    # @example Access list
    #   User.group_access(group, ['read', 'create'])
    #   #=> [#<User id: 1, ...>, ...]
    #
    # @return [Array<Class>]
    def group_access(group_id, access)
      group_id = ensure_group_id_parameter(group_id)
      access   = ensure_group_access_list_parameter(access)

      # check direct access
      instances = joins(group_through.name)
                  .where( group_through.table_name => { group_id: group_id, access: access }, active: true )

      if method_defined?(:permissions?)
        permissions = Permission.with_parents('ticket.agent')
        instances = instances
                    .joins(roles: :permissions)
                    .where(roles: { active: true }, permissions: { name: permissions, active: true })
      end

      # check indirect access through roles if possible
      return instances if !respond_to?(:role_access)

      # combines and removes duplicates
      # and returns them in one statement
      instances | role_access(group_id, access)
    end

    # The reflection instance containing the association data
    #
    # @example
    #   User.group_through
    #   #=> <ActiveRecord::Reflection::HasManyReflection:0x007fd2f5785440 @name=:user_groups, ...>
    #
    # @return [ActiveRecord::Reflection::HasManyReflection] The given map
    def group_through
      @group_through ||= reflect_on_association(group_through_identifier)
    end

    # The identifier of the has_many :through relation
    #
    # @example
    #   User.group_through_identifier
    #   #=> :user_groups
    #
    # @return [Symbol] The relation identifier
    def group_through_identifier
      :"#{name.downcase}_groups"
    end

    def ensure_group_id_parameter(group_or_id)
      return group_or_id if group_or_id.is_a?(Integer)

      group_or_id.id
    end

    def ensure_group_access_list_parameter(access)
      access = [access] if access.is_a?(String)
      access.push('full') if access.exclude?('full')
      access
    end
  end
end
