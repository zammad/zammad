# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Backport of https://github.com/mikel/mail/pull/1692 for issue #6461.
#
# Outlook labels code page 936 (GBK) as 'gb2312' and writes the euro sign as
# the single byte 0x80. The gem decodes 'gb2312' in subjects, display names and
# attachment file names as GB18030, which rejects that byte, so the euro sign
# became '�'. It also leaves most aliases of GB2312 and GBK unresolved, which
# `TextEncoding` relies on for bodies.
#
# Remove this file and its spec once Zammad uses a mail release that includes
# the PR.

module Mail
  module Utilities
    # Resolves a charset to the encoding it names: 'gb2312' to GB2312, and the
    # GB2312, GB18030 and GBK labels Ruby does not know.
    module PickGbEncoding
      def pick_encoding(charset)
        case charset.to_s.downcase
        when %r{\Agb[-_]?2312([-_]?80)?\z}, 'csgb2312', 'chinese', 'iso-ir-58', 'csiso58gb231280'
          Encoding::GB2312
        when %r{\Agb[-_]?18030([-_]\d{4})?\z}
          Encoding::GB18030
        when 'csgbk', 'cp-936', 'ms936', 'windows-936', 'windows936', 'x-gbk'
          Encoding::GBK
        else
          super
        end
      end
    end

    singleton_class.prepend PickGbEncoding

    # Reads GB2312 and GBK as GB18030, their superset, and a lone 0x80 as the
    # euro sign, like the WHATWG gb18030 decoder. Other invalid sequences become
    # U+FFFD, in a copy, so that the caller's bytes are never rewritten.
    module DecodeGbAsGb18030
      GB18030_EURO_SIGN        = "\xA2\xE3".b.force_encoding(Encoding::GB18030).freeze
      GB18030_REPLACEMENT_CHAR = "\x84\x31\xA4\x37".b.force_encoding(Encoding::GB18030).freeze

      def encode(string, charset)
        encoded = super
        encoded.force_encoding(Encoding::GB18030) if [Encoding::GB2312, Encoding::GBK].include?(encoded.encoding)
        return encoded if encoded.encoding != Encoding::GB18030 || encoded.valid_encoding?

        encoded.scrub do |bytes|
          bytes.bytesize == 1 && bytes.getbyte(0) == 0x80 ? GB18030_EURO_SIGN : GB18030_REPLACEMENT_CHAR
        end
      end
    end

    StrictCharsetEncoder.prepend DecodeGbAsGb18030
    BestEffortCharsetEncoder.prepend DecodeGbAsGb18030
  end
end
