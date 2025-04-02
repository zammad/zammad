# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Adds certain (missing) meta data when creating email articles.
module Ticket::Article::AddsMetadataWhatsapp
  extend ActiveSupport::Concern

  included do
    before_create :ticket_article_add_metadata_whatsapp
  end

  private

  # We need to add a real article type layer, to handle such situations in the future.
  def ticket_article_add_metadata_whatsapp
    return if !neither_importing_nor_postmaster?
    return if !sender_needs_metadata?
    return if !type_whatsapp_needs_metadata?

    metadata_whatsapp_process_from_and_to
  end

  def type_whatsapp_needs_metadata?
    return false if !type_id

    type = Ticket::Article::Type.lookup(id: type_id)
    return false if type&.name != 'whatsapp message'

    true
  end

  def whatsapp_from_name(channel)
    if created_by_id != 1
      return "#{created_by.firstname} #{created_by.lastname} via #{channel.options[:name]} (#{channel.options[:phone_number]})"
    end

    "#{channel.options[:name]} (#{channel.options[:phone_number]})"
  end

  def whatsapp_to_name
    phone_number = ticket.preferences.dig('whatsapp', 'from', 'phone_number')
    display_name = ticket.preferences.dig('whatsapp', 'from', 'display_name')

    "#{display_name} (+#{phone_number})"
  end

  def metadata_whatsapp_process_from_and_to
    channel = Channel.lookup(id: ticket.preferences['channel_id'])

    return if !channel

    self.from = whatsapp_from_name(channel)
    self.to = whatsapp_to_name
  end
end
