# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A channel a message goes out over — SMS, Telegram, WhatsApp, Facebook —, one class per channel in this directory: the
#   article type it takes, the channel area it needs, and what it asks of the ticket and the text before the message is
#   stored. An addon adds a channel the same way, without a list to change. Email is none of these: the group sends it.
class Service::AI::Tool::CreateArticle::Preparation::Channel
  class_attribute :article_type, :area, :label, :text_limit, instance_accessor: false

  attr_reader :ticket, :channel, :arguments, :data

  # @param channel [::Channel] the ticket's channel, active and of the area
  # @param arguments [Hash] the tool's arguments
  # @param data [Hash] the article as prepared so far, which the channel completes
  def initialize(ticket:, channel:, arguments:, data:)
    @ticket    = ticket
    @channel   = channel
    @arguments = arguments
    @data      = data
  end

  class << self
    # @param type [String] an article type
    # @return [Class, nil] the channel that delivers it
    def for_type(type)
      descendants.find { |channel| channel.article_type == type }
    end

    # @return [Array<String>] the article types a channel delivers
    def article_types
      descendants.map(&:article_type).sort
    end

    # The channel a ticket's messages go out over.
    #
    # @return [::Channel, nil]
    def of(ticket)
      ::Channel.find_by(id: ticket.preferences['channel_id'])
    end

    # Whether a message of the channel's type answers a message of the given type.
    def replies_to?(source_type)
      source_type == article_type
    end

    # What the channel asks of the text and the ticket before a message goes out — also of a draft an agent sends
    #   later, who would only learn of it then.
    def check(ticket:, arguments:)
      invalid("#{label} text must not exceed #{text_limit} characters.") if text_limit && arguments[:text].length > text_limit
    end

    # The recipient the caller names, where the channel takes one.
    #
    # @return [String, nil] none where the ticket's destination is used
    def recipient(_arguments)
      nil
    end

    def invalid(message)
      raise Service::AI::Tool::CreateArticle::Preparation::InvalidArticle, message
    end

    private

    # @param type [String] the article type the channel delivers
    # @param area [String] the area of the channel as Zammad configures it, such as 'Sms::Account'
    # @param label [String] the channel's name in a refusal
    # @param text_limit [Integer, nil] the characters a message may hold
    def delivers(type, area:, label:, text_limit: nil)
      self.article_type = type
      self.area         = area
      self.label        = label
      self.text_limit   = text_limit
    end
  end

  # Completes the article's data, or refuses the message.
  def prepare
    raise NotImplementedError
  end

  private

  def invalid(message)
    self.class.invalid(message)
  end

  # Last, because loading the channels runs their declarations, which need the methods above.
  include Mixin::RequiredSubPaths
end
