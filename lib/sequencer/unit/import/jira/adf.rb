# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Converts an Atlassian Document Format (ADF) node - the rich text structure
# Jira returns for descriptions and comments - into a plain text string.
#
# Only text content is extracted; media/attachments are not resolved. This is
# intentional: the importer stores the textual content and links back to the
# original Jira issue for anything richer.
module Sequencer::Unit::Import::Jira::Adf
  BLOCK_TYPES = %w[paragraph heading listItem codeBlock blockquote bulletList orderedList table tableRow].freeze

  def adf_to_text(node)
    return '' if node.blank?

    case node['type']
    when 'text'
      node['text'].to_s
    when 'hardBreak'
      "\n"
    when 'mention'
      "@#{node.dig('attrs', 'text') || node.dig('attrs', 'displayName')}"
    when 'emoji'
      node.dig('attrs', 'text') || node.dig('attrs', 'shortName').to_s
    when 'inlineCard'
      node.dig('attrs', 'url').to_s
    else
      children = Array(node['content']).map { |child| adf_to_text(child) }.join
      children += "\n" if BLOCK_TYPES.include?(node['type'])
      children
    end
  end
end
