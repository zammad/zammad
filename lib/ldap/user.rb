class Ldap

  # Class for handling LDAP Groups.
  #  ATTENTION: Make sure to add the following lines to your code if accessing this class.
  #  Otherwise Rails will autoload the Group model or might throw parameter errors if crearing
  #  an ::Ldap instance.
  #
  # @example
  #  require 'ldap'
  #  require 'ldap/user'
  class User
    include Ldap::FilterLookup

    BLACKLISTED = [
      :admincount,
      :accountexpires,
      :badpasswordtime,
      :badpwdcount,
      :countrycode,
      :distinguishedname,
      :dnshostname,
      :dscorepropagationdata,
      :instancetype,
      :iscriticalsystemobject,
      :useraccountcontrol,
      :usercertificate,
      :objectclass,
      :objectcategory,
      :objectguid,
      :objectsid,
      :primarygroupid,
      :pwdlastset,
      :lastlogoff,
      :lastlogon,
      :lastlogontimestamp,
      :localpolicyflags,
      :lockouttime,
      :logoncount,
      :logonhours,
      :'msdfsr-computerreferencebl',
      :'msds-supportedencryptiontypes',
      :ridsetreferences,
      :samaccounttype,
      :memberof,
      :serverreferencebl,
      :serviceprincipalname,
      :showinadvancedviewonly,
      :usnchanged,
      :usncreated,
      :whenchanged,
      :whencreated,
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
      %i(samaccountname userprincipalname uid dn).each { |attribute|
        next if attributes[attribute].blank?
        result = attribute.to_s
        break
      }
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
    #  require 'ldap'
    #  require 'ldap/user'
    #  ldap_user = Ldap::User.new
    #
    # @return [nil]
    def initialize(config = nil, ldap: nil)
      @ldap = ldap || ::Ldap.new(config)

      handle_config(config)
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
        base: @ldap.base_dn,
        filter: "(#{uid_attribute}=#{username})",
        password: password
      )

      message = bind_success ? 'successful' : 'failed'
      Rails.logger.info "ldap authentication for user '#{username}' (#{uid_attribute}) #{message}!"
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
    def attributes(filter: nil, base_dn: nil)

      filter ||= filter()

      attributes       = {}
      known_attributes = BLACKLISTED.dup
      lookup_counter   = 1

      @ldap.search(filter, base: base_dn) do |entry|
        new_attributes = entry.attribute_names - known_attributes

        if new_attributes.blank?
          lookup_counter += 1
          # check max 50 entries with
          # the same attributes in a row
          break if lookup_counter == 50
          next
        end

        new_attributes.each do |attribute|
          value = entry[attribute]
          next if value.blank?
          next if value[0].blank?

          example_value         = value[0].force_encoding('UTF-8').encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
          attributes[attribute] = "#{attribute} (e. g. #{example_value})"
        end

        known_attributes.concat(new_attributes)
        lookup_counter = 0
      end
      attributes
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

    def handle_config(config)
      return if config.blank?
      @uid_attribute = config[:uid_attribute]
      @filter        = config[:filter]
    end
  end
end
