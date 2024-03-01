# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Class for establishing LDAP connections. A wrapper around Net::LDAP needed for Auth and Sync.
# ATTENTION: Loads custom 'net/ldap/entry' from 'lib/core_ext' which extends the Net::LDAP::Entry class.
#
# @!attribute [r] connection
#   @return [Net::LDAP] the Net::LDAP instance with the established connection
# @!attribute [r] base_dn
#   @return [String] the base dn used while initializing the connection
class Ldap
  DEFAULT_PORT = 389

  attr_reader :base_dn, :host, :port

  # Initializes a LDAP connection.
  #
  # @param [Hash] config the configuration for establishing a LDAP connection.
  # @option config [String] :host The LDAP explicit host. May contain the port.
  # @option config [Number] :port The LDAP port. Default is 389 LDAP or 636 for LDAPS. Gets overwritten when it's given inside the host.
  # @option config [Boolean] :ssl The LDAP SSL setting. Sets Port to 636 if non other is given.
  # @option config [String] :base_dn The base DN searches etc. are applied to.
  # @option config [String] :bind_user The username which should be used for bind.
  # @option config [String] :bind_pw The password which should be used for bind.
  #
  # @example
  #  ldap = Ldap.new
  #
  # @return [nil]
  def initialize(config)
    @config = config

    # connect on initialization
    connection
  end

  # Requests the rootDSE (the root of the directory data tree on a directory server).
  #
  # @example
  #  ldap.preferences
  #  #=> [:namingcontexts=>["DC=domain,DC=tld", "CN=Configuration,DC=domain,DC=tld"], :supportedldapversion=>["3", "2"], ...]
  #
  # @return [Hash{String => Array<String>}] The found RootDSEs.
  def preferences
    connection.search_root_dse.to_h
  end

  # Performs a LDAP search and yields over the found LDAP entries.
  #
  # @param filter [String] The filter that should get applied to the search.
  # @param base [String] The base DN on which the search should get executed. Default is initialization parameter.
  # @param scope [Net::LDAP::SearchScope] The search scope as defined in Net::LDAP SearchScopes. Default is WholeSubtree.
  # @param attributes [Array<String>] Limits the requested entry attributes to the given list of attributes which increses the performance.
  #
  # @example
  #  ldap.search('(objectClass=group)') do |entry|
  #    p entry
  #  end
  #  #=> <Net::LDAP::Entry...>
  #
  # @return [true] Returns always true
  def search(filter, base: nil, scope: nil, attributes: nil, &)

    base  ||= base_dn
    scope ||= Net::LDAP::SearchScope_WholeSubtree

    connection.search(
      base:          base,
      filter:        filter,
      scope:         scope,
      attributes:    attributes,
      return_result: false, # improves performance
      &
    )
  end

  # Checks if there are any entries for the given search criteria.
  #
  # @param (see Ldap#search)
  #
  # @example
  #  ldap.entries?('(objectClass=group)')
  #  #=> true
  #
  # @return [Boolean] Returns true if entries are present false if not.
  def entries?(*)
    found = false
    search(*) do |_entry|
      found = true
      break
    end
    found
  end

  # Counts the entries for the given search criteria.
  #
  # @param (see Ldap#search)
  #
  # @example
  #  ldap.entries?('(objectClass=group)')
  #  #=> 10
  #
  # @return [Number] The count of matching entries.
  def count(*)
    counter = 0
    search(*) do |_entry|
      counter += 1
    end
    counter
  end

  def connection
    @connection ||= begin
      attributes_from_config
      binded_connection
    end
  end

  private

  def binded_connection
    # ldap connect
    ldap = Net::LDAP.new(connection_params)

    # set auth data if needed
    if @bind_user && @bind_pw
      ldap.auth @bind_user, @bind_pw
    end

    return ldap if ldap.bind

    result = ldap.get_operation_result
    raise Exceptions::UnprocessableEntity, "Can't bind to '#{@host}', #{result.code}, #{result.message}"
  rescue => e
    Rails.logger.error e
    raise Exceptions::UnprocessableEntity, "Can't connect to '#{@host}' on port '#{@port}', #{e}"
  end

  def connection_params
    params = {
      host: @host,
      port: @port,
    }

    if @encryption
      params[:encryption] = @encryption
    end

    # special workaround for IBM bluepages
    # see issue #1422 for more details
    if @host == 'bluepages.ibm.com'
      params[:force_no_page] = true
    end

    params
  end

  def attributes_from_config
    # might change below
    @host = @config[:host]
    @port = @config[:port]

    parse_host
    handle_ssl_config
    handle_bind_crendentials

    @base_dn = @config[:base_dn]

    # fallback to default
    # port if none given
    @port ||= DEFAULT_PORT # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def parse_host
    return if @host !~ %r{\A([^:]+):(.+?)\z}

    @host = $1
    @port = $2.to_i
  end

  def handle_ssl_config
    return if @config.fetch(:ssl, 'off').eql?('off')

    ssl_default_port = DEFAULT_PORT
    if @config[:ssl].eql?('ssl')
      ssl_default_port = 636

      @encryption = {
        method: :simple_tls,
      }
    else
      @encryption = {
        method: :start_tls,
      }
    end

    @port ||= @config.fetch(:port, ssl_default_port)

    if @config[:ssl_verify]
      Certificate::ApplySSLCertificates.ensure_fresh_ssl_context
      @encryption[:tls_options] = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
      return
    end

    @encryption[:tls_options] = {
      verify_mode: OpenSSL::SSL::VERIFY_NONE
    }
  end

  def handle_bind_crendentials
    @bind_user = @config[:bind_user]
    @bind_pw   = @config[:bind_pw]
  end

end
