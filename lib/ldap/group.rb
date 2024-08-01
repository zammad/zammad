# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ldap

  # Class for handling LDAP Groups.
  class Group
    include Ldap::FilterLookup

    # Returns the uid attribute.
    #
    # @example
    #  Ldap::Group.uid_attribute
    #
    # @return [String] The uid attribute.
    def self.uid_attribute
      'dn'
    end

    # Initializes a wrapper around Net::LDAP and ::Ldap to handle LDAP groups.
    #
    # @param [Hash] config the configuration for establishing a LDAP connection. Default is Setting 'ldap_config'.
    # @option config [String] :uid_attribute The uid attribute. Default is determined automatically.
    # @option config [String] :filter The filter for LDAP groups. Default is determined automatically.
    # @param ldap [Ldap] An optional existing Ldap class instance. Default is a new connection with given configuration.
    #
    # @example
    #  ldap_group = Ldap::Group.new
    #
    # @return [nil]
    def initialize(config = nil, ldap: nil)
      @ldap = ldap || ::Ldap.new(config)

      handle_config(config)
    end

    # Lists available LDAP groups.
    #
    # @param filter [String] The filter for listing groups. Default is initialization parameter.
    # @param base_dn [String] The applied base DN for listing groups. Default is Ldap#base_dn.
    #
    # @example
    #  ldap_group.list
    #  #=> {"cn=zamamd role admin,ou=zamamd groups,ou=test,dc=domain,dc=tld"=>"cn=zamamd role admin,ou=zamamd groups,ou=test,dc=domain,dc=tld", ...}
    #
    # @return [Hash{String=>String}] List of available LDAP groups.
    def list(filter: nil, base_dn: nil)

      filter ||= filter()

      # don't start a search if no filter was found
      return {} if filter.blank?

      groups = {}
      @ldap.search(filter, base: base_dn, attributes: %w[dn]) do |entry|
        groups[entry.dn.downcase] = entry.dn.downcase
      end
      groups
    end

    # Creates a mapping for user DN and local role IDs based on a given group DN to local role ID mapping.
    #
    # @param mapping [Hash{String=>String}] The group DN to local role mapping.
    # @param filter [String] The filter for finding groups. Default is initialization parameter.
    #
    # @example
    #  mapping = {"cn=access control assistance operators,cn=builtin,dc=domain,dc=tld"=>"1", ...}
    #  ldap_group.user_roles(mapping)
    #  #=> {"cn=s-1-5-11,cn=foreignsecurityprincipals,dc=domain,dc=tld"=>[1, 2], ...}
    #
    # @return [Hash{String=>Array<Number>}] The user DN to local role IDs mapping.
    def user_roles(mapping, filter: nil)

      filter ||= filter()

      result = {}
      @ldap.search(filter, attributes: %w[dn member memberuid uniquemember]) do |entry|

        roles = mapping[entry.dn.downcase]
        next if roles.blank?

        members = group_user_dns(entry)
        next if members.blank?

        members.each do |user_dn|
          user_dn_key = user_dn.downcase

          roles.each do |role|
            role = role.to_i

            result[user_dn_key] ||= []
            next if result[user_dn_key].include?(role)

            result[user_dn_key].push(role)
          end
        end
      end

      result
    end

    # The active filter of the instance. If none give on initialization an automatic lookup is performed.
    #
    # @example
    #  ldap_group.filter
    #  #=> '(objectClass=group)'
    #
    # @return [String, nil] The active or found filter or nil if none could be found.
    def filter
      @filter ||= lookup_filter(['(objectClass=groupOfUniqueNames)', '(objectClass=groupOfNames)', '(objectClass=group)', '(objectClass=posixgroup)', '(objectClass=organization)'])
    end

    # The active uid attribute of the instance. If none give on initialization an automatic lookup is performed.
    #
    # @example
    #  ldap_group.uid_attribute
    #  #=> 'dn'
    #
    # @return [String, nil] The active or found uid attribute or nil if none could be found.
    def uid_attribute
      @uid_attribute ||= self.class.uid_attribute
    end

    private

    def handle_config(config)
      return if config.blank?

      @uid_attribute = config[:uid_attribute]
      @filter        = config[:filter]
      @user_filter   = config[:user_filter]
    end

    def group_user_dns(entry)
      return entry[:member] if entry[:member].present?
      # workaround for windows ad's with more than 1500 group users
      # https://metacpan.org/dist/perl-ldap/view/lib/Net/LDAP/FAQ.pod#How-do-I-search-for-all-members-of-a-large-group-in-AD
      return group_user_memberof(entry) if entry.to_h.keys.any? { |key| key.to_s.include?('member;range') }
      return group_user_dns_memberuid(entry) if entry[:memberuid].present?

      entry[:uniquemember].presence
    end

    def group_user_dns_memberuid(entry)
      entry[:memberuid].filter_map do |uid|
        dn = nil
        @ldap.search("(&(uid=#{uid})#{@user_filter})", attributes: %w[dn]) do |user|
          dn = user.dn
        end
        dn
      end
    end

    def group_user_memberof(entry)
      result = []
      @ldap.search("(&(memberOf=#{entry.dn})#{@user_filter})", attributes: %w[dn]) do |user|
        result << user.dn
      end
      result
    end
  end
end
