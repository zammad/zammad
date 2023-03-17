# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::InternalTicketLinks < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :mapped

  def process
    return if !contains_internal_ticket_link?(mapped[:body])

    provide_mapped do
      {
        body: replaced_internal_ticket_links,
      }
    end
  end

  private

  def contains_internal_ticket_link?(string)
    return false if string.blank?

    string.include?('/agent/tickets/')
  end

  def replaced_internal_ticket_links
    body_html = Nokogiri::HTML(mapped[:body])

    body_html.css('a').each do |node|
      next if !contains_internal_ticket_link?(node['href'])

      node.attributes['href'].value = convert_link(node['href'])
    end

    body_html.to_html
  end

  def convert_link(link)
    link.sub! '/agent/tickets/', '/#ticket/zoom/'
  end
end
