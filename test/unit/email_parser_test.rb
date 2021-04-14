# rubocop:disable all

require 'test_helper'

class EmailParserTest < ActiveSupport::TestCase

=begin

to write new .yml files for emails you can use the following code:

File.write('test/data/mail/mailXXX.yml', Channel::EmailParser.new.parse(File.read('test/data/mail/mailXXX.box')).slice(:from, :from_email, :from_display_name, :to, :cc, :subject, :body, :content_type, :'reply-to', :attachments).to_yaml)

=end

  test 'parse' do
    msg_files = Dir.glob(Rails.root.join('test', 'data', 'mail', 'mail*.box')).sort
    messages = []
    msg_files.each do |f|
      next if !File.exists?(f.ext('yml'))
      item = {
        source:  File.basename(f),
        content: YAML.load(File.read(f.ext('yml'))),
        parsed:  Channel::EmailParser.new.parse(File.read(f)),
      }
      messages.push item
    end

    messages.each do |m|

      # assert: raw content hash is a subset of parsed message hash
      expected_msg = m[:content].except(:attachments)
      parsed_msg = m[:parsed].slice(*expected_msg.keys)

      expected_msg.each do |key, value|
        if value.nil?
          assert_nil(parsed_msg[key], "parsed message data does not match test/data/mail/#{m[:source]}: #{key}")
        else
          assert_equal(value, parsed_msg[key], "parsed message data does not match test/data/mail/#{m[:source]}: #{key}")
        end
      end

      # assert: attachments in parsed message hash match metadata in raw hash
      next if m[:content][:attachments].blank?
      attachments_found = []
      m[:content][:attachments].each do |expected_attachment|
        expected_attachment_md5 = Digest::MD5.hexdigest(expected_attachment[:data])
        m[:parsed][:attachments].each do |parsed_attachment|
          parsed_attachment_md5 = Digest::MD5.hexdigest(parsed_attachment[:data])
          next if attachments_found.include?(parsed_attachment_md5)
          next if expected_attachment_md5 != parsed_attachment_md5
          attachments_found.push parsed_attachment_md5
          expected_attachment.each do |key, value|
            assert_equal(value, parsed_attachment[key], "#{key} is different in test/data/mail/#{m[:source]}")
          end
          next
        end
      end
      next if attachments_found.count == m[:content][:attachments].count
      m[:content][:attachments].each do |expected_attachment|
        next if attachments_found.include?(Digest::MD5.hexdigest(expected_attachment[:data]))
        assert(false, "Attachment not found test/data/mail/#{m[:source]}: #{expected_attachment.inspect}")
      end
    end
  end
end
