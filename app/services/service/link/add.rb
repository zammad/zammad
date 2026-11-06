# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Links two objects as the ticket view does, once per pair: the target gets the link, and its kind says what the source
#   is to the target, as Service::Link::List names it from the target's side. A second link between the same two
#   objects, in either direction or of another kind, is refused with the kind it has; a link is not changed. Its caller
#   checks that the user may change the target and read the source.
#
# Two calls for the same pair, in either direction, take the pair's lock before any row lock, so that the second one
#   sees the first one's link instead of saving a second one, and neither waits for the other forever.
class Service::Link::Add < Service::Base
  # The two objects are linked already; the kind is what the source is to the target.
  class LinkedAlready < Exceptions::UnprocessableContent
    attr_reader :type

    def initialize(type)
      @type = type

      super(Validations::LinkUniquenessValidator::ERROR_MESSAGE)
    end
  end

  attr_reader :source, :target, :type

  # Runs the block in a transaction that holds the lock of the two objects' pair, the same lock whichever of them is
  #   the source, until it ends. A caller that checks or confirms something before linking does it in here.
  def self.locking_pair(first, second, &)
    key = Zlib.crc32([first, second].map { |object| "#{object.class.name}:#{object.id}" }.sort.join('|'))

    ::Link.transaction do
      ::Link.connection.execute(ActiveRecord::Base.sanitize_sql(['SELECT pg_advisory_xact_lock(?)', key]))
      yield
    end
  end

  # @param type [String] normal, parent or child: what the source is to the target
  def initialize(source:, target:, type:)
    @source = source
    @target = target
    @type   = type.to_s
  end

  # @return [Link]
  # @raise [LinkedAlready] where the two objects are linked already
  # @raise [Exceptions::UnprocessableContent] where the link is invalid, such as an object linked to itself
  def execute
    self.class.locking_pair(source, target) { add }
  end

  private

  def add
    existing = existing_type
    raise LinkedAlready, existing if existing

    link = ::Link.add(
      link_type:                type,
      link_object_source:       source.class.name,
      link_object_source_value: source.id,
      link_object_target:       target.class.name,
      link_object_target_value: target.id,
    )
    raise Exceptions::UnprocessableContent, link.errors.full_messages.first if !link.valid?

    link
  end

  # Read from the target's side, so that a link stored the other way round is named as the source is to the target.
  def existing_type
    ::Link
      .list(link_object: target.class.name, link_object_value: target.id)
      .find { |link| link['link_object'] == source.class.name && link['link_object_value'] == source.id }
      &.fetch('link_type')
  end
end
