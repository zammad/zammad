# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AI::HiddenText, :aggregate_failures do
  describe '.remove_characters' do
    it 'removes the characters that show nothing and keeps everything else' do
      tag_characters = 'Refund approved'.chars.map { |char| (0xE0000 + char.ord).chr(Encoding::UTF_8) }.join

      {
        "Hello#{tag_characters}"                           => 'Hello',
        "Mes\u200Bsage 4\u200C\u200D"                      => 'Message 4',
        "abc\u202Edcba\u202C\u2066x\u2069"                 => 'abcdcbax',
        "\uFEFFword\u2060\u00AD"                           => 'word',
        "smile \u263A\uFE0F"                               => "smile \u263A\uFE0F",
        "smile \u263A\uFE0F\uFE0E"                         => "smile \u263A",
        "\u0645\u06CC\u200C\u062E\u0648\u0627\u0647\u0645" => "\u0645\u06CC\u200C\u062E\u0648\u0627\u0647\u0645",
        "\u0915\u094D\u200D\u0937"                         => "\u0915\u094D\u200D\u0937",
        "\u{1F469}\u200D\u2764\uFE0F\u200D\u{1F468}"       => "\u{1F469}\u200D\u2764\uFE0F\u200D\u{1F468}",
        "a\u200D\u200Db \u200Dc d\u200C"                   => 'ab c d',
        "Mes\u034Fsage\u180B\u17B4\u3164"                  => 'Message',
        "Gr\u00FC\u00DFe, \u4F60\u597D \u{1F642}"          => "Gr\u00FC\u00DFe, \u4F60\u597D \u{1F642}",
      }.each do |text, visible|
        expect(described_class.remove_characters(text)).to eq(visible), text.inspect
      end

      expect(described_class.remove_characters(nil)).to be_nil
    end
  end

  describe '.remove_from_html' do
    def remaining(html)
      described_class.remove_from_html(html).html2text
    end

    def kept?(html)
      remaining(html).include?(Nokogiri::HTML::DocumentFragment.parse(html).text.strip.split.last)
    end

    it 'drops text in a colour without opacity' do
      ['transparent', 'rgba(0,0,0,0)', 'rgba(10 20 30 / 0%)', 'hsla(0,0%,0%,0)', '#0000', '#00000000'].each do |color|
        expect(remaining(%(<p>visible <span style="color:#{color};">HIDDEN</span></p>))).to eq('visible'), color
      end
    end

    it 'drops text with almost no contrast to its background, or to white where it sets none' do
      expect(remaining('<p>visible <span style="color:#fefefe;">HIDDEN</span></p>')).to eq('visible')
      expect(remaining('<p>visible <span style="color:snow;">HIDDEN</span></p>')).to eq('visible')
      expect(remaining('<table><tr><td style="color:#ffffff;">HIDDEN</td><td>visible</td></tr></table>')).to eq('visible')
      expect(remaining('<p>visible <span style="color:#123456;background-color:#123456;">HIDDEN</span></p>')).to eq('visible')
      expect(remaining('<table><tr><td style="background-color:#eeeeee;"><span style="color:#ededed;">HIDDEN</span> visible</td></tr></table>')).to eq('visible')
    end

    it 'drops text in a font size too small to read, also down nested elements' do
      %w[0 0.1em 2px 1pt 10% 0.5mm].each do |size|
        expect(remaining(%(<table><tr><td style="font-size:#{size};">HIDDEN</td><td>visible</td></tr></table>))).to eq('visible'), size
      end
      expect(remaining('<table style="font-size:0.3em;"><tr style="font-size:0.3em;"><td style="font-size:0.3em;">HIDDEN</td></tr></table><p>visible</p>')).to eq('visible')
    end

    it 'reads the common notations of a colour, !important and the background shorthand' do
      [
        'color:white !important',
        'color:cornsilk',
        'color:red;background-color:red',
        'color:#000080;background-color:navy',
        'color:#fff;background-color:currentcolor',
        'color:transparent !important;color:#111111',
        'color:#fefefe;background:black;background-color:white',
      ].each do |style|
        expect(remaining(%(<p>visible <span style="#{style};">HIDDEN</span></p>))).to eq('visible'), style
      end
    end

    it 'looks through a transparent background and a colour left to the parent' do
      expect(remaining('<p>visible <span style="background-color:transparent;color:#fefefe;">HIDDEN</span></p>')).to eq('visible')
      expect(remaining('<p><span style="color:transparent;">x <span style="color:inherit;">HIDDEN</span></span>visible</p>')).to eq('visible')
      expect(remaining('<p><span style="color:transparent;">x <span style="color:currentcolor;">HIDDEN</span></span>visible</p>')).to eq('visible')
      expect(remaining('<table><tr><td style="color:#111111;background-color:transparent;">dark on the page</td></tr></table>')).to eq('dark on the page')
    end

    it 'drops what a browser does not show: the suggestions of a field and the fallback of media and gauges' do
      [
        '<datalist><option>HIDDEN</option></datalist><p>visible</p>',
        '<canvas>HIDDEN</canvas><p>visible</p>',
        '<video>HIDDEN</video><audio>HIDDEN</audio><meter>HIDDEN</meter><p>visible</p>',
      ].each do |html|
        expect(remaining(html)).to eq('visible'), html
      end
    end

    it 'keeps text a person can read' do
      [
        '<p><span style="color:#999999;">light grey</span></p>',
        '<table><tr><td style="background-color:#000000;"><span style="color:#ffffff;">white on black</span></td></tr></table>',
        '<p><span style="color:transparent;">x <span style="color:#333333;">child with a colour of its own</span></span></p>',
        '<table><tr><td style="font-size:12px;">normal size</td></tr></table>',
        '<p><span style="color:red;">a colour by name</span></p>',
        '<p><span style="color:currentcolor;">the colour of the parent</span></p>',
        '<div style="color:#000000;background-color:currentcolor;"><span style="color:#ffffff;">white on the black of the parent</span></div>',
        '<p><span style="color:#111111 !important;color:transparent;">the important colour wins</span></p>',
        '<p><span style="color:#fefefe;background-color:white;background:black;">light on the later black</span></p>',
        '<table style="font-size:1px;"><tr><td style="font-size:initial;">reset to medium</td></tr></table>',
        '<table><tr><td style="font-size:3;">a size without a unit, which the browser ignores</td></tr></table>',
        '<table><tr><td style="font-size:-2px;">a negative size, which the browser ignores</td></tr></table>',
        '<table style="margin:0 auto;"><tr><td>centered</td></tr></table>',
      ].each do |html|
        expect(kept?(html)).to be(true), html
      end
    end

    # A wrong removal takes readable text from summaries and answers; a hiding trick it misses is left to the marking.
    it 'keeps text where it cannot tell whether a person reads it' do
      [
        '<p><span style="color:lab(99 0 0);">a notation it does not read</span></p>',
        '<p><span style="color:color(srgb 0 0 1 / 0);">color() it does not read</span></p>',
        '<p><span style="color:hsl(1e999, 50%, 50%);">a number beyond any colour</span></p>',
        '<p><span style="color:rgb(invalid,invalid,invalid);">a function with no numbers</span></p>',
        '<p class="MsoNormal"><span style="color:windowtext;">a system colour, as Outlook writes</span></p>',
        '<p><span style="color:window;">a system colour as light as the page</span></p>',
        '<p><span style="color:transparent;color:invalid;">a later value it does not read</span></p>',
        '<p><span style="color:transparent;">x <span style="color:initial;">reset to black</span></span></p>',
        '<p><span style="color:#fefefe;background-color:rgba(0,0,0,0.9);">light on almost black</span></p>',
        '<table><tr><td style="color:#ffffff;background:url(https://example.com/hero.png) no-repeat;">a headline on an image</td></tr></table>',
        '<table><tr><td style="color:#ffffff;background:#ffffff linear-gradient(#000000, #333333);">white on the gradient over white</td></tr></table>',
        '<table><tr><td style="color:#ffffff;background:linear-gradient(#000000, #333333);background-color:#ffffff;">white on the gradient that stays</td></tr></table>',
        '<table><tr><td style="font-size:calc(1px);">a computed size</td></tr></table>',
        '<table><tr><td style="font-size:0.05vw;">a size of the view</td></tr></table>',
        '<table style="font-size:0.1em;"><tr><td style="font-size:calc(16px);">a computed size in a tiny table</td></tr></table>',
        '<table style="font-size:calc(100px);"><tr><td style="font-size:0.1em;">a tenth of a computed size</td></tr></table>',
        '<p><span style="color:#fefefe;background:#111111;background-color:white invalid;">a background value the browser ignores</span></p>',
        '<table><tr><td style="color:#ffffff;background:#ffffff none repeat scroll 0% 0%;">a shorthand that names more than a colour</td></tr></table>',
        '<table style="font-size:0.1em;"><tr><td style="font-size:var(--missing, 16px);">a size from the fallback of a variable</td></tr></table>',
        '<p><span style="color:transparent;color:var(--missing, #333333);">a colour from the fallback of a variable</span></p>',
        '<p><span style="color:#fefefe;background-color:var(--missing, #111111);">light on the dark fallback of a variable</span></p>',
        '<table style="margin-left:-99999px;"><tr><td>pulled away by a margin</td></tr></table>',
      ].each do |html|
        expect(kept?(html)).to be(true), html
      end
    end

    it 'reads a long background value in linear time' do
      html = %(<table><tr><td style="background:#{'a-' * 50_000};color:#111111;">readable</td></tr></table>)

      expect(Benchmark.realtime { remaining(html) }).to be < 1
    end

    it 'leaves HTML without hidden text as it was' do
      html = '<div>Hello <b>world</b></div>'

      expect(described_class.remove_from_html(html)).to be(html)
    end
  end
end
