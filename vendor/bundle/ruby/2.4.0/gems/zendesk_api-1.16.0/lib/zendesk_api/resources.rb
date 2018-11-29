module ZendeskAPI
  # @internal The following are redefined later, but needed by some circular resources (e.g. Ticket -> User, User -> Ticket)

  class Ticket < Resource; end
  class Forum < Resource; end
  class User < Resource; end
  class Category < Resource; end
  class OrganizationMembership < ReadResource; end
  class OrganizationSubscription < ReadResource; end

  # @internal Begin actual Resource definitions

  class Locale < ReadResource; end

  class CustomRole < DataResource; end

  class Role < DataResource
    def to_param
      name
    end
  end

  class Topic < Resource; end
  class Bookmark < Resource; end
  class Ability < DataResource; end
  class Group < Resource; end
  class SharingAgreement < ReadResource; end
  class JobStatus < ReadResource; end

  class Session < ReadResource
    include Destroy
  end

  class Tag < DataResource
    include Update
    include Destroy

    alias :name :id
    alias :to_param :id

    def path(opts = {})
      raise "tags must have parent resource" unless association.options.parent
      super(opts.merge(:with_parent => true, :with_id => false))
    end

    def changed?
      true
    end

    def destroy!
      super do |req|
        req.body = attributes_for_save
      end
    end

    module Update
      def _save(method = :save)
        return self unless @resources

        @client.connection.post(path) do |req|
          req.body = { :tags => @resources.reject(&:destroyed?).map(&:id) }
        end

        true
      rescue Faraday::Error::ClientError => e
        if method == :save
          false
        else
          raise e
        end
      end
    end

    def attributes_for_save
      { self.class.resource_name => [id] }
    end
  end

  class Attachment < Data
    def initialize(client, attributes)
      attributes[:file] ||= attributes.delete(:id)

      super
    end

    def save
      upload = Upload.create!(@client, attributes)
      self.token = upload.token
    end

    def to_param
      token
    end
  end

  class Upload < Data
    include Create
    include Destroy

    def id
      token
    end

    has_many Attachment

    private

    def attributes_for_save
      attributes.changes
    end
  end

  class MobileDevice < Resource
    # Clears this devices' badge
    put :clear_badge
  end

  class Organization < Resource
    has Ability, :inline => true
    has Group

    has_many Ticket
    has_many User
    has_many Tag, :extend => Tag::Update, :inline => :create
    has_many OrganizationMembership
    has_many :subscriptions, class: OrganizationSubscription

    # Gets a incremental export of organizations from the start_time until now.
    # @param [Client] client The {Client} object to be used
    # @param [Integer] start_time The start_time parameter
    # @return [Collection] Collection of {Organization}
    def self.incremental_export(client, start_time)
      ZendeskAPI::Collection.new(client, self, :path => "incremental/organizations?start_time=#{start_time.to_i}")
    end
  end

  class Brand < Resource
    def destroy!
      self.active = false
      save!

      super
    end
  end

  class ForumSubscription < Resource
    has Forum
    has User
  end

  class OrganizationMembership < ReadResource
    include Create
    include Destroy

    extend CreateMany
    extend DestroyMany

    has User
    has Organization
  end

  class OrganizationSubscription < ReadResource
    include Create
    include Destroy

    has User
    has Organization
  end

  class Forum < Resource
    has Category
    has Organization
    has Locale

    has_many Topic
    has_many :subscriptions, :class => ForumSubscription
  end

  class Category < Resource
    has_many Forum
  end

  class TopicSubscription < Resource
    has Topic
    has User
  end

  class TopicComment < Data
    has Topic
    has User
    has_many Attachment
  end

  class Topic < Resource
    class TopicComment < TopicComment
      include Read
      include Create
      include Update
      include Destroy

      has_many :uploads, :class => Attachment, :inline => true

      def self.import!(client, attributes)
        new(client, attributes).tap do |comment|
          comment.save!(:path => 'import/' + comment.path)
        end
      end

      def self.import(client, attributes)
        comment = new(client, attributes)
        return unless comment.save(:path => 'import/' + comment.path)
        comment
      end
    end

    class TopicVote < SingularResource
      has Topic
      has User

      private

      def attributes_for_save
        attributes.changes
      end
    end

    has Forum
    has_many :comments, :class => TopicComment
    has_many :subscriptions, :class => TopicSubscription
    has :vote, :class => TopicVote
    has_many Tag, :extend => Tag::Update, :inline => :create
    has_many Attachment
    has_many :uploads, :class => Attachment, :inline => true

    def votes(opts = {})
      return @votes if @votes && !opts[:reload]

      association = ZendeskAPI::Association.new(:class => TopicVote, :parent => self, :path => 'votes')
      @votes = ZendeskAPI::Collection.new(@client, TopicVote, opts.merge(:association => association))
    end

    def self.import!(client, attributes)
      new(client, attributes).tap do |topic|
        topic.save!(:path => "import/topics")
      end
    end

    def self.import(client, attributes)
      topic = new(client, attributes)
      return unless topic.save(:path => "import/topics")
      topic
    end
  end

  class Activity < Resource
    has User
    has :actor, :class => User
  end

  class Setting < UpdateResource
    attr_reader :on

    def initialize(client, attributes = {})
      # Try and find the root key
      @on = (attributes.keys.map(&:to_s) - %w{association options}).first

      # Make what's inside that key the root attributes
      attributes.merge!(attributes.delete(@on))

      super
    end

    def new_record?
      false
    end

    def path(options = {})
      super(options.merge(:with_parent => true))
    end

    def attributes_for_save
      { self.class.resource_name => { @on => attributes.changes } }
    end
  end

  class SatisfactionRating < ReadResource
    has :assignee, :class => User
    has :requester, :class => User
    has Ticket
    has Group
  end

  class Search
    class Result < Data; end

    # Creates a search collection
    def self.search(client, options = {})
      unless (%w{query external_id} & options.keys.map(&:to_s)).any?
        warn "you have not specified a query for this search"
      end

      ZendeskAPI::Collection.new(client, self, options)
    end

    # Quack like a Resource
    # Creates the correct resource class from the result_type passed in
    def self.new(client, attributes)
      result_type = attributes["result_type"]

      if result_type
        result_type = ZendeskAPI::Helpers.modulize_string(result_type)
        klass = ZendeskAPI.const_get(result_type) rescue nil
      end

      (klass || Result).new(client, attributes)
    end

    class << self
      def resource_name
        "search"
      end

      alias :resource_path :resource_name

      def model_key
        "results"
      end
    end
  end

  class Request < Resource
    class Comment < DataResource
      include Save

      has_many :uploads, :class => Attachment, :inline => true
      has :author, :class => User

      def save
        if new_record?
          save_associations
          true
        else
          false
        end
      end

      alias :save! :save
    end

    has Comment, :inline => true
    has_many Comment

    has Organization
    has Group
    has :requester, :class => User
  end

  class AnonymousRequest < CreateResource
    def self.singular_resource_name
      'request'
    end

    namespace 'portal'
  end

  class TicketField < Resource; end

  class TicketMetric < DataResource
    include Read
  end

  class TicketRelated < DataResource; end

  class TicketEvent < DataResource
    class Event < Data; end

    has_many :child_events, :class => Event
    has Ticket
    has :updater, :class => User

    # Gets a incremental export of ticket events from the start_time until now.
    # @param [Client] client The {Client} object to be used
    # @param [Integer] start_time The start_time parameter
    # @return [Collection] Collection of {TicketEvent}
    def self.incremental_export(client, start_time)
      ZendeskAPI::Collection.new(client, self, :path => "incremental/ticket_events?start_time=#{start_time.to_i}")
    end
  end

  class Ticket < Resource
    extend CreateMany
    extend UpdateMany
    extend DestroyMany

    class Audit < DataResource
      class Event < Data
        has :author, :class => User
      end

      put :trust

      # need this to support SideLoading
      has :author, :class => User

      has_many Event
    end

    class Comment < DataResource
      include Save

      has_many :uploads, :class => Attachment, :inline => true
      has :author, :class => User

      def save
        if new_record?
          save_associations
          true
        else
          false
        end
      end

      alias :save! :save
    end

    class SatisfactionRating < CreateResource
      class << self
        alias :resource_name :singular_resource_name
      end
    end

    put :mark_as_spam
    post :merge

    has :requester, :class => User, :inline => :create
    has :submitter, :class => User
    has :assignee, :class => User

    has_many :collaborators, :class => User, :inline => true, :extend => (Module.new do
      def to_param
        map(&:id)
      end
    end)

    has_many Audit
    has :metrics, :class => TicketMetric
    has Group
    has :forum_topic, :class => Topic
    has Organization
    has Brand
    has :related, :class => TicketRelated

    has Comment, :inline => true
    has_many Comment

    has :last_comment, :class => Comment, :inline => true
    has_many :last_comments, :class => Comment, :inline => true

    has_many Tag, :extend => Tag::Update, :inline => :create

    has_many :incidents, :class => Ticket

    # Gets a incremental export of tickets from the start_time until now.
    # @param [Client] client The {Client} object to be used
    # @param [Integer] start_time The start_time parameter
    # @return [Collection] Collection of {Ticket}
    def self.incremental_export(client, start_time)
      ZendeskAPI::Collection.new(client, self, :path => "exports/tickets?start_time=#{start_time.to_i}")
    end

    # Imports a ticket through the imports/tickets endpoint using save!
    # @param [Client] client The {Client} object to be used
    # @param [Hash] attributes The attributes to create.
    # @return [Ticket] Created object or nil
    def self.import!(client, attributes)
      new(client, attributes).tap do |ticket|
        ticket.save!(:path => "imports/tickets")
      end
    end

    # Imports a ticket through the imports/tickets endpoint
    # @param [Client] client The {Client} object to be used
    # @param [Hash] attributes The attributes to create.
    # @return [Ticket] Created object or nil
    def self.import(client, attributes)
      ticket = new(client, attributes)
      return unless ticket.save(:path => "imports/tickets")
      ticket
    end
  end

  class SuspendedTicket < ReadResource
    include Destroy

    # Recovers this suspended ticket to an actual ticket
    put :recover
  end

  class UserViewRow < DataResource
    has User
    def self.model_key
      "rows"
    end
  end

  class ViewRow < DataResource
    has Ticket

    # @internal Optional columns

    has Group
    has :assignee, :class => User
    has :requester, :class => User
    has :submitter, :class => User
    has Organization

    def self.model_key
      "rows"
    end
  end

  class RuleExecution < Data
    has_many :custom_fields, :class => TicketField
  end

  class ViewCount < DataResource; end

  class Rule < Resource
    private

    def attributes_for_save
      to_save = [:conditions, :actions, :output].inject({}) { |h, k| h.merge(k => send(k)) }
      { self.class.singular_resource_name.to_sym => attributes.changes.merge(to_save) }
    end
  end

  module Conditions
    def all_conditions=(all_conditions)
      self.conditions ||= {}
      self.conditions[:all] = all_conditions
    end

    def any_conditions=(any_conditions)
      self.conditions ||= {}
      self.conditions[:any] = any_conditions
    end

    def add_all_condition(field, operator, value)
      self.conditions ||= {}
      self.conditions[:all] ||= []
      self.conditions[:all] << { :field => field, :operator => operator, :value => value }
    end

    def add_any_condition(field, operator, value)
      self.conditions ||= {}
      self.conditions[:any] ||= []
      self.conditions[:any] << { :field => field, :operator => operator, :value => value }
    end
  end

  module Actions
    def add_action(field, value)
      self.actions ||= []
      self.actions << { :field => field, :value => value }
    end
  end

  class View < Rule
    include Conditions

    has_many :tickets, :class => Ticket
    has_many :feed, :class => Ticket, :path => "feed"

    has_many :rows, :class => ViewRow, :path => "execute"
    has :execution, :class => RuleExecution
    has ViewCount, :path => "count"

    def add_column(column)
      columns = execution.columns.map(&:id)
      columns << column
      self.columns = columns
    end

    def columns=(columns)
      self.output ||= {}
      self.output[:columns] = columns
    end

    def self.preview(client, options = {})
      Collection.new(client, ViewRow, options.merge(:path => "views/preview", :verb => :post))
    end
  end

  class Trigger < Rule
    include Conditions
    include Actions

    has :execution, :class => RuleExecution
  end

  class Automation < Rule
    include Conditions
    include Actions

    has :execution, :class => RuleExecution
  end

  class Macro < Rule
    include Actions

    has :execution, :class => RuleExecution

    # Returns the update to a ticket that happens when a macro will be applied.
    # @param [Ticket] ticket Optional {Ticket} to apply this macro to.
    # @raise [Faraday::Error::ClientError] Raised for any non-200 response.
    def apply!(ticket = nil)
      path = "#{self.path}/apply"

      if ticket
        path = "#{ticket.path}/#{path}"
      end

      response = @client.connection.get(path)
      SilentMash.new(response.body.fetch("result", {}))
    end

    # Returns the update to a ticket that happens when a macro will be applied.
    # @param [Ticket] ticket Optional {Ticket} to apply this macro to
    def apply(ticket = nil)
      apply!(ticket)
    rescue Faraday::Error::ClientError
      SilentMash.new
    end
  end

  class UserView < Rule
    def self.preview(client, options = {})
      Collection.new(client, UserViewRow, options.merge!(:path => "user_views/preview", :verb => :post))
    end
  end

  class GroupMembership < Resource
    extend CreateMany
    extend DestroyMany

    has User
    has Group
  end

  class User < Resource
    extend CreateMany
    extend UpdateMany
    extend DestroyMany

    class TopicComment < TopicComment
      include Read
    end

    class GroupMembership < Resource
      put :make_default
    end

    class Identity < Resource
      # Makes this identity the primary one bumping all other identities down one
      put :make_primary

      # Verifies this identity
      put :verify

      # Requests verification for this identity
      put :request_verification
    end

    any :password

    # Set a user's password
    def set_password(opts = {})
      password(opts.merge(:verb => :post))
    end

    # Change a user's password
    def change_password(opts = {})
      password(opts.merge(:verb => :put))
    end

    # Set a user's password
    def set_password!(opts = {})
      password!(opts.merge(:verb => :post))
    end

    # Change a user's password
    def change_password!(opts = {})
      password!(opts.merge(:verb => :put))
    end

    # Gets a incremental export of users from the start_time until now.
    # @param [Client] client The {Client} object to be used
    # @param [Integer] start_time The start_time parameter
    # @return [Collection] Collection of {User}
    def self.incremental_export(client, start_time)
      ZendeskAPI::Collection.new(client, self, :path => "incremental/users?start_time=#{start_time.to_i}")
    end

    has Organization

    class Session < Resource
    end

    class CurrentSession < SingularResource
      class << self
        def singular_resource_name
          'session'
        end

        alias :resource_name :singular_resource_name
      end
    end

    has_many Session

    def current_session
      ZendeskAPI::User::CurrentSession.find(@client, :user_id => 'me')
    end

    delete :logout

    def clear_sessions!
      @client.connection.delete(path + '/sessions')
    end

    def clear_sessions
      clear_sessions!
    rescue ZendeskAPI::Error::ClientError
      false
    end

    has CustomRole, :inline => true, :include => :roles
    has Role, :inline => true, :include_key => :name
    has Ability, :inline => true

    has_many Identity

    has_many Request
    has_many :requested_tickets, :class => Ticket, :path => 'tickets/requested'
    has_many :ccd_tickets, :class => Ticket, :path => 'tickets/ccd'

    has_many Group
    has_many GroupMembership
    has_many Topic
    has_many OrganizationMembership
    has_many OrganizationSubscription

    has_many ForumSubscription
    has_many TopicSubscription
    has_many :topic_comments, :class => TopicComment
    has_many :topic_votes, :class => Topic::TopicVote

    has_many Setting
    has_many Tag, :extend => Tag::Update, :inline => :create

    def attributes_for_save
      # Don't send role_id, it's necessary
      # for side-loading, but causes problems on save
      # see #initialize
      attrs = attributes.changes.delete_if do |k, _|
        k == "role_id"
      end

      { self.class.singular_resource_name => attrs }
    end

    def handle_response(*)
      super

      # Needed for proper Role sideloading
      self.role_id = role.name if key?(:role)
    end
  end

  class UserField < Resource; end
  class OrganizationField < Resource; end

  class OauthClient < Resource
    namespace "oauth"

    def self.singular_resource_name
      "client"
    end
  end

  class OauthToken < ReadResource
    include Destroy
    namespace "oauth"

    def self.singular_resource_name
      "token"
    end
  end

  class Target < Resource; end

  module Voice
    include DataNamespace

    class PhoneNumber < Resource
      namespace "channels/voice"
    end

    class Address < Resource
      namespace "channels/voice"
    end

    class Greeting < Resource
      namespace "channels/voice"
    end

    class GreetingCategory < Resource
      namespace "channels/voice"
    end

    class Ticket < CreateResource
      namespace "channels/voice"
    end

    class Agent < ReadResource
      namespace "channels/voice"

      class Ticket < CreateResource
        def new_record?
          true
        end

        def self.display!(client, options)
          new(client, options).tap do |resource|
            resource.save!(path: resource.path + '/display')
          end
        end
      end

      has_many Ticket
    end
  end

  class TicketForm < Resource
    # TODO
    # post :clone
  end

  class AppInstallation < Resource
    namespace "apps"

    def self.singular_resource_name
      "installation"
    end

    # Don't nest attributes
    def attributes_for_save
      attributes.changes
    end

    def handle_response(response)
      @attributes.replace(response.body) if response.body
    end
  end

  class AppNotification < CreateResource
    class << self
      def resource_path
        "apps/notify"
      end
    end

    # Don't nest attributes
    def attributes_for_save
      attributes.changes
    end

    def handle_response(response)
      @attributes.replace(response.body) if response.body.is_a?(Hash)
    end
  end

  class App < Resource
    def initialize(client, attributes = {})
      attributes[:upload_id] ||= nil

      super
    end

    def self.create!(client, attributes = {}, &block)
      if file_path = attributes.delete(:upload)
        attributes[:upload_id] = client.apps.uploads.create!(:file => file_path).id
      end

      super
    end

    class Plan < Resource
    end

    class Upload < Data
      class << self
        def resource_path
          "uploads"
        end
      end

      include Create

      def initialize(client, attributes)
        attributes[:file] ||= attributes.delete(:id)

        super
      end

      # Not nested under :upload, just returns :id
      def save!(*)
        super.tap do
          attributes.id = @response.body["id"]
        end
      end

      # Always save
      def changed?
        true
      end

      # Don't nest attributes
      def attributes_for_save
        attributes
      end
    end

    def self.uploads(client, *args, &block)
      ZendeskAPI::Collection.new(client, Upload, *args, &block)
    end

    def self.installations(client, *args, &block)
      ZendeskAPI::Collection.new(client, AppInstallation, *args, &block)
    end

    has Upload, :path => "uploads"
    has_many Plan

    # Don't nest attributes
    def attributes_for_save
      attributes.changes
    end

    def handle_response(response)
      @attributes.replace(response.body) if response.body
    end
  end

  module DynamicContent
    include DataNamespace

    class Item < ZendeskAPI::Resource
      namespace 'dynamic_content'

      class Variant < ZendeskAPI::Resource
      end

      has_many Variant
    end
  end

  class PushNotificationDevice < DataResource
    def self.destroy_many(client, tokens)
      ZendeskAPI::Collection.new(
        client, self, "push_notification_devices" => tokens,
        :path => "push_notification_devices/destroy_many",
        :verb => :post
      )
    end
  end
end
