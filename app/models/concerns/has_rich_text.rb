# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module HasRichText
  extend ActiveSupport::Concern

  included do
    class_attribute :has_rich_text_attributes
    self.has_rich_text_attributes = [].freeze
    attr_accessor :has_rich_text_attachments_cache
    attr_accessor :form_id

    before_save :has_rich_text_parse
    after_save :has_rich_text_commit_cache
    after_save :has_rich_text_pickup_attachments
    after_save :has_rich_text_cleanup_unused_attachments
  end

=begin

Checks if file is used inline

@param store_object [Store] attachment to evaluate
@return [Bool] if attachment is inline

@example
  store_object = Store.first
  HasRichText.attachment_inline?(::CanAssets.reduce(list, {})

=end

  def self.attachment_inline?(store_object)
    store_object.preferences&.dig('Content-Disposition') == 'inline'
  end

  private

  def has_rich_text_parse # rubocop:disable Naming/PredicateName
    has_rich_text_attributes.each { |attr| has_rich_text_parse_attribute(attr) }
  end

  def has_rich_text_parse_attribute(attr) # rubocop:disable Naming/PredicateName
    image_prefix = "#{self.class.name}_#{attr}"
    raw = send(attr)
    return if raw.blank?

    parsed = Loofah.scrub_fragment(raw, HtmlSanitizer::CidToSrc.new).to_s
    parsed = HtmlSanitizer.strict(parsed)
    parsed = Loofah.scrub_fragment(parsed, HtmlSanitizer::RemoveLineBreaks.new).to_s

    (parsed, attachments_inline) = HtmlSanitizer.replace_inline_images(parsed, image_prefix)

    send(:"#{attr}=", parsed)

    self.has_rich_text_attachments_cache ||= []
    self.has_rich_text_attachments_cache += attachments_inline
  end

  def has_rich_text_commit_cache # rubocop:disable Naming/PredicateName
    return if has_rich_text_attachments_cache.blank?

    has_rich_text_attachments_cache.each do |attachment_cache|
      Store.create!(
        object:      self.class.name,
        o_id:        id,
        data:        attachment_cache[:data],
        filename:    attachment_cache[:filename],
        preferences: attachment_cache[:preferences],
      )
    end
  end

  def attributes_with_association_ids
    attrs = super

    self.class.has_rich_text_attributes.each do |attr|
      attrs[attr.to_s] = send(:"#{attr}_with_urls")
    end

    attrs
  end

  def has_rich_text_pickup_attachments # rubocop:disable Naming/PredicateName
    return if form_id.blank?

    self.attachments = Store.list(
      object: 'UploadCache',
      o_id:   form_id,
    )
  end

  def has_rich_text_cleanup_unused_attachments # rubocop:disable Naming/PredicateName
    active_cids = has_rich_text_attributes.each_with_object([]) do |elem, memo|
      memo.concat HasRichText.extract_inline_cids(send(elem))
    end

    attachments
      .select { |file| HasRichText.attachment_inline?(file) }
      .reject { |file| active_cids.include? file.preferences&.dig('Content-ID') }
      .each   { |file| Store.remove_item(file.id) }
  end

  class_methods do
    def has_rich_text(*attrs) # rubocop:disable Naming/PredicateName
      (self.has_rich_text_attributes += attrs.map(&:to_sym)).freeze

      attrs.each do |attr|
        define_method :"#{attr}_with_urls" do
          HasRichText.insert_urls(send(attr), attachments)
        end
      end
    end
  end

  class << self
    def insert_urls(raw, attachments)
      scrubber = Loofah::Scrubber.new do |node|
        next if node.name != 'img'
        next if !node['src']&.start_with?('cid:')

        cid = node['src'].sub(%r{^cid:}, '')
        lookup_cids = [cid, "<#{cid}>"]

        attachment = attachments.find do |file|
          lookup_cids.include? file.preferences&.dig('Content-ID')
        end

        next if !attachment

        node['cid'] = cid
        node['src'] = Rails.application.routes.url_helpers.attachment_path(attachment.id)
      end

      Loofah.scrub_fragment(raw, scrubber).to_s
    end

    def extract_inline_cids(raw)
      inline_cids = []

      scrubber = Loofah::Scrubber.new do |node|
        next if node.name != 'img'
        next if !node['src']&.start_with? 'cid:'

        cid = node['src'].sub(%r{^cid:}, '')
        inline_cids << cid
      end

      Loofah.scrub_fragment(raw, scrubber)

      inline_cids
    end
  end
end
