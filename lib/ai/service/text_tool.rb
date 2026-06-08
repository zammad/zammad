# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Service::TextTool < AI::Service
  def self.lookup_attributes(context_data, _locale)
    {
      identifier:   'text_tool',
      triggered_by: context_data[:text_tool],
    }
  end

  def self.lookup_version(context_data, _locale)
    "#{context_data[:text_tool].id}-#{context_data[:text_tool].cache_version}"
  end

  def analytics?
    true
  end

  private

  def post_transform_result(result)
    user_prompt_has_paragraphs = paragraphs?(prompt_user)

    if user_prompt_has_paragraphs && !paragraphs?(result)
      paragraphs = result.to_s.split(%r{\r?\n\r?\n+}).map(&:strip).reject(&:empty?)
      result = paragraphs.map { |paragraph| "<p>#{paragraph}</p>" }.join
    elsif !user_prompt_has_paragraphs && !paragraphs?(result) && result.match?(%r{\r?\n})
      result = result.to_s.gsub(%r{\r?\n}, '<br>')
    end

    result
  end

  def transform_user_prompt(prompt)
    if prompt.match?(%r{<div[^>]*data-signature\s*=\s*["']true["']}i)
      fragment = Nokogiri::HTML::DocumentFragment.parse(prompt.to_s)

      fragment.css('div').each do |div|
        next if div['data-signature'] == 'true'
        next if div.ancestors.any? { |a| a['data-signature'] == 'true' }

        div.name = 'p'
      end

      return fragment.to_html(indent: 0).delete("\n")
    end

    prompt.gsub(%r{<div( [^>]*)?>}i, '<p\1>').gsub(%r{</div>}i, '</p>')
  end

  def paragraphs?(text)
    text.match?(%r{<p( [^>]*)?>}i)
  end

  def options
    {
      temperature: 0.1,
    }
  end

  def json_response?
    false
  end
end
