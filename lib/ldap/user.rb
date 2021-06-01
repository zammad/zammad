# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Ldap

  # Class for handling LDAP Groups.
  #  ATTENTION: Make sure to add the following lines to your code if accessing this class.
  #  Otherwise Rails will autoload the Group model or might throw parameter errors if crearing
  #  an ::Ldap instance.
  #
  # @example
  #  require_dependency 'ldap'
  #  require_dependency 'ldap/user'
  class User
    include Ldap::FilterLookup

    BLACKLISTED = %i[
      admincount
      accountexpires
      badpasswordtime
      badpwdcount
      countrycode
      distinguishedname
      dnshostname
      dscorepropagationdata
      instancetype
      iscriticalsystemobject
      useraccountcontrol
      usercertificate
      objectclass
      objectcategory
      objectsid
      primarygroupid
      pwdlastset
      lastlogoff
      lastlogon
      lastlogontimestamp
      localpolicyflags
      lockouttime
      logoncount
      logonhours
      msdfsr-computerreferencebl
      msds-supportedencryptiontypes
      ridsetreferences
      samaccounttype
      memberof
      serverreferencebl
      serviceprincipalname
      showinadvancedviewonly
      usnchanged
      usncreated
      whenchanged
      whencreated
    ].freeze

    # Returns the uid attribute.
    #
    # @param attributes [Hash{Symbol=>Array<String>}] A list of LDAP User attributes which should get checked for available uids.
    #
    # @example
    #  Ldap::User.uid_attribute(attributes)
    #
    # @return [String] The uid attribute.
    def self.uid_attribute(attributes)
      result = nil
      %i[objectguid entryuuid samaccountname userprincipalname uid dn].each do |attribute|
        next if attributes[attribute].blank?

        result = attribute.to_s
        break
      end
      result
    end

    # Initializes a wrapper around Net::LDAP and ::Ldap to handle LDAP users.
    #
    # @param [Hash] config the configuration for establishing a LDAP connection. Default is Setting 'ldap_config'.
    # @option config [String] :uid_attribute The uid attribute. Default is determined automatically.
    # @option config [String] :filter The filter for LDAP users. Default is determined automatically.
    # @param ldap [Ldap] An optional existing Ldap class instance. Default is a new connection with given configuration.
    #
    # @example
    #  require_dependency 'ldap'
    #  require_dependency 'ldap/user'
    #  ldap_user = Ldap::User.new
    #
    # @return [nil]
    def initialize(config = nil, ldap: nil)
      @config = config || Setting.get('ldap_config')
      @ldap   = ldap || ::Ldap.new(@config)

      handle_config
    end

    # Checks if given username and password combination is valid for the connected LDAP.
    #
    # @param username [String] The username.
    # @param password [String] The password.
    #
    # @example
    #  ldap_user.valid?('example_user', 'pw1234')
    #  #=> true
    #
    # @return [Boolean] The valid state of the username and password combination.
    def valid?(username, password)
      bind_success = @ldap.connection.bind_as(
        base:     @ldap.base_dn,
        filter:   "(#{login_attribute}=#{username})",
        password: password
      )

      message = bind_success ? 'successful' : 'failed'
      Rails.logger.info "ldap authentication for user '#{username}' (#{login_attribute}) #{message}!"
      bind_success.present?
    end

    # Determines possible User attributes with example values.
    #
    # @param filter [String] The filter for listing users. Default is initialization parameter.
    # @param base_dn [String] The applied base DN for listing users. Default is Ldap#base_dn.
    #
    # @example
    #  ldap_user.attributes
    #  #=> {:dn=>"dn (e. g. CN=Administrator,CN=Users,DC=domain,DC=tld)", ...}
    #
    # @return [Hash{Symbol=>String}] The available User attributes as key and the name and an example as value.
    def attributes(custom_filter: nil, base_dn: nil)
      @attributes ||= begin
        attributes     = {}.with_indifferent_access
        lookup_counter = 0

        # collect sample attributes
        @ldap.search(custom_filter || filter, base: base_dn) do |entry|
          pre_merge_count = attributes.count

          attributes.reverse_merge!(entry.to_h
                                         .except(*BLACKLISTED)
                                         .transform_values(&:first)
                                         .compact)

          # check max 50 entries with the same attributes in a row
          lookup_counter = (pre_merge_count < attributes.count ? 0 : lookup_counter.next)
          break if lookup_counter >= 50
        end

        # format sample values for presentation
        attributes.each do |name, value|
          attributes[name] = if value.encoding == Encoding.find('ascii-8bit')
                               "#{name} (binary data)"
                             else
                               "#{name} (e.g., #{value.utf8_encode})"
                             end
        end
      end
    end

    # The active filter of the instance. If none give on initialization an automatic lookup is performed.
    #
    # @example
    #  ldap_user.filter
    #  #=> '(objectClass=user)'
    #
    # @return [String, nil] The active or found filter or nil if none could be found.
    def filter
      @filter ||= lookup_filter(['(&(objectClass=user)(samaccountname=*)(!(samaccountname=*$)))', '(objectClass=user)', '(objectClass=posixaccount)', '(objectClass=person)'])
    end

    # The active uid attribute of the instance. If none give on initialization an automatic lookup is performed.
    #
    # @example
    #  ldap_user.uid_attribute
    #  #=> 'samaccountname'
    #
    # @return [String, nil] The active or found uid attribute or nil if none could be found.
    def uid_attribute
      @uid_attribute ||= self.class.uid_attribute(attributes)
    end

    private

    attr_reader :config

    def login_attribute
      @login_attribute ||= config[:user_attributes]&.key('login') || uid_attribute
    end

    def handle_config
      return if config.blank?

      @uid_attribute = config[:uid_attribute]
      @filter        = config[:filter]
    end
  end
end
