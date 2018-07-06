# rubocop:disable all

require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase
  test 'parse' do
    msg_files = Dir.glob(Rails.root.join('test', 'data', 'mail', 'mail*.box')).sort

    messages = msg_files.select { |f| File.exists?(f.ext('yml')) }
                        .map do |f|
                          {
                            source:  File.basename(f),
                            content: YAML.load(File.read(f.ext('yml'))),
                            parsed:  Channel::EmailParser.new.parse(File.read(f)),
                          }
                        end

    messages.each do |m|
      # assert: raw content hash is a subset of parsed message hash
      expected_msg = m[:content].except(:attachments)
      parsed_msg = m[:parsed].slice(*expected_msg.keys)
      failure_msg = [parsed_msg, expected_msg]
                      .map(&:to_a).map(&:sort).reduce(&:zip)
                      .reject { |a| a.uniq.one? }
                      .map { |a, b| "#{a.first.upcase}\n  #{m[:source]}: #{a.last}\n  #{m[:source].ext('yml')}: #{b.last}" }
                      .join("\n")

      assert_operator(expected_msg, :<=, parsed_msg,
                      "parsed message data does not match message content:\n" +
                      failure_msg)

      # assert: attachments in parsed message hash match metadata in raw hash
      next if m[:content][:attachments].blank?

      # the formats of m[:content][:attachments] and m[:parsed][:attachments] don't match,
      # so we have to convert one to the other
      parsed_attachment_metadata = m[:parsed][:attachments].map do |a|
                                     {
                                       md5:      Digest::MD5.hexdigest(a[:data]),
                                       cid:      a[:preferences]['Content-ID'],
                                       filename: a[:filename],
                                     }.with_indifferent_access
                                   end

      m[:content][:attachments].sort_by { |a| a[:md5] }
       .zip(parsed_attachment_metadata.sort_by { |a| a[:md5] })
       .each do |content, parsed|
        assert_operator(content, :<=, parsed,
                        "parsed attachment data from #{m[:source]} does not match " \
                        "attachment metadata from #{m[:source].ext('yml')}")
      end
    end
  end
end
