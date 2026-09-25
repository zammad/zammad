# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ContentTranslation::Html do
  subject(:document) { described_class.new(html) }

  let(:html) { '<p>Hello <b>John</b>,</p><p>read <a href="https://example.com/doc">the guide</a> and run <code>vpn</code>.</p>' }

  def translation(response)
    document.translate(response)
  end

  describe '#to_s' do
    it 'sends every section with its marker, emphasis as Markdown and other elements as markers' do
      expect(document.to_s).to eq("{s1}\nHello **John**,\n{s2}\nread {1}the guide{/1} and run {2/}.")
    end

    context 'with nested blocks, lists, tables, quotes and signatures' do
      let(:html) do
        <<~HTML
          <div>
            <div>Intro <div>Nested</div> outro</div>
            <ul><li>One<ul><li>Two</li></ul></li></ul>
            <table><tr><td>Cell</td><td><img src="cid:1"></td></tr></table>
            <blockquote>On Monday, Anna wrote:<br><br>Question?</blockquote>
            <div class="signature">--<br>Anna Admin</div>
          </div>
        HTML
      end

      it 'sends a section per run of text between blocks, with line breaks' do
        expect(document.to_s).to eq(<<~TEXT.strip)
          {s1}
          Intro
          {s2}
          Nested
          {s3}
          outro
          {s4}
          One
          {s5}
          Two
          {s6}
          Cell
          {s7}
          On Monday, Anna wrote:

          Question?
          {s8}
          --
          Anna Admin
        TEXT
      end
    end

    context 'with content that is protected or has no text' do
      let(:html) { '<p><img src="cid:1"></p><pre>ls -la</pre><p><span translate="no">Zammad</span></p><p>&nbsp;</p>' }

      it 'sends nothing' do
        expect(document.sections).to be_empty
      end
    end

    context 'with protected content inside text' do
      let(:html) { '<p>Run <code>ls</code>, <kbd>Ctrl</kbd> and <span translate="NO">Zammad</span> <svg><text>x</text></svg>.</p>' }

      it 'sends placeholders for it' do
        expect(document.to_s).to eq("{s1}\nRun {1/}, {2/} and {3/} {4/}.")
      end
    end

    context 'with an element around the whole section' do
      let(:html) { '<p> <span style="color:red"><a href="https://example.com">Whole <i>link</i></a></span> </p>' }

      it 'sends no marker for it' do
        expect(document.to_s).to eq("{s1}\nWhole *link*")
      end
    end

    context 'with runs of identical spans, as Word writes them' do
      let(:html) { '<p><span style="font-size:11pt">One sentence</span> <span style="font-size:11pt">split up.</span> <span style="font-size:12pt">Other</span></p>' }

      it 'sends them as one marker' do
        expect(document.to_s).to eq("{s1}\n{1}One sentence split up.{/1} {2}Other{/2}")
      end
    end

    context 'with whitespace and comments of the HTML source' do
      let(:html) { "<p>Hello\n    <!--[if gte mso 9]><xml>x</xml><![endif]-->world\t!</p>" }

      it 'sends the text as it is displayed' do
        expect(document.to_s).to eq("{s1}\nHello world !")
      end
    end

    context 'with characters that are Markdown or markers' do
      let(:html) { '<p>2 * 3 = {s1} {1} snake_case \\ path</p>' }

      it 'escapes them' do
        expect(document.to_s).to eq("{s1}\n2 \\* 3 = \\{s1\\} \\{1\\} snake_case \\\\ path")
      end
    end

    describe 'emphasis' do
      {
        'plain'                       => ['<b>bold</b> and <em>italic</em>', '**bold** and *italic*', '<strong>bold</strong> and <em>italic</em>'],
        'with surrounding whitespace' => ['a<b> bold </b>b', 'a **bold** b', 'a <strong>bold</strong> b'],
        'inside a word'               => ['un<i>believ</i>able', 'un*believ*able', 'un<em>believ</em>able'],
        'with attributes'             => ['a <b class="x">bold</b>', 'a {1}bold{/1}', 'a <b class="x">bold</b>'],
        'with a line break'           => ['<b>one<br>two</b> three', "**one\ntwo** three", '<strong>one<br>two</strong> three'],
        'nested in itself'            => ['<b>a <strong>b</strong></b> c', '**a **b**** c', '<strong>a <strong>b</strong></strong> c'],
        'next to itself'              => ['<b>a</b><b>b</b> c', '**a****b** c', '<strong>a</strong><strong>b</strong> c'],
        'nested in the other kind'    => ['<b>a <i>b</i></b> c', '**a *b*** c', '<strong>a <em>b</em></strong> c'],
        'around the other kind'       => ['<b><i>both</i></b> x', '***both*** x', '<em><strong>both</strong></em> x'],
        'next to the other kind'      => ['<b>a</b><i>b</i> c', '**a***b* c', '<strong>a</strong><em>b</em> c'],
        'next to punctuation'         => ['word<b>"quote"</b> x', 'word**"quote"** x', 'word<strong>"quote"</strong> x'],
        'around a marker'             => ['word<b><a href="x">link</a></b> x', 'word**{1}link{/1}** x', 'word<strong><a href="x">link</a></strong> x'],
        'around a literal asterisk'   => ['2 * 3 and <b>*</b> x', '2 \\* 3 and **\\*** x', '2 * 3 and <strong>*</strong> x'],
        'inside after punctuation'    => ['<b>Please read (<i>carefully</i>)</b> first.', '**Please read (*carefully*)** first.', '<strong>Please read (<em>carefully</em>)</strong> first.'],
        'inside a link inside bold'   => ['<b><a href="x"><i>Italic</i> link</a></b> x', '**{1}*Italic* link{/1}** x', '<strong><a href="x"><em>Italic</em> link</a></strong> x'],
        'at the end of a link'        => ['<b>See <a href="x">the <i>guide</i></a></b> x', '**See {1}the *guide*{/1}** x', '<strong>See <a href="x">the <em>guide</em></a></strong> x'],
      }.each do |description, (source, sent, rebuilt)|
        context "when #{description}" do
          let(:html) { "<p>#{source}</p>" }

          it 'sends it as Markdown where no attributes have to be restored' do
            expect(document.to_s).to eq("{s1}\n#{sent}")
          end

          it 'reads it back' do
            expect(translation(document.to_s)).to eq("<p>#{rebuilt}</p>")
          end
        end
      end
    end

    context 'with line breaks the CSS displays' do
      let(:html) { "<p style=\"white-space: pre-wrap\">First line\nSecond  line <span style=\"white-space: normal\">not\nthis</span></p>" }

      it 'sends them as line breaks' do
        expect(document.to_s).to eq("{s1}\nFirst line\nSecond  line {1}not this{/1}")
      end

      it 'restores them as line breaks' do
        expect(translation("{s1}\nErste Zeile\nZweite  Zeile {1}nicht dies{/1}"))
          .to eq('<p style="white-space: pre-wrap">Erste Zeile<br>Zweite  Zeile <span style="white-space: normal">nicht dies</span></p>')
      end
    end

    context 'with a white-space declaration that is overridden in the same style' do
      let(:html) { "<p style=\"white-space: pre-wrap; white-space: normal\">First line\nSecond line</p>" }

      it 'follows the last one' do
        expect(document.to_s).to eq("{s1}\nFirst line Second line")
      end
    end

    context 'with right-to-left text' do
      let(:html) { '<p dir="rtl">مرحبا <b>بالعالم</b></p>' }

      it 'sends it like any other text' do
        expect(document.to_s).to eq("{s1}\nمرحبا **بالعالم**")
      end
    end

    context 'with malformed HTML' do
      let(:html) { '<p>Unclosed <b>bold <i>and</p><div>next</b> block' }

      it 'sends the text as it is parsed' do
        expect(document.to_s).to eq("{s1}\nUnclosed **bold *and***\n{s2}\n***next*** *block*")
      end
    end

    context 'with a null character' do
      let(:html) { "<p>Hello\u0000world</p>" }

      it 'sends the text without it' do
        expect(document.to_s).to eq("{s1}\nHelloworld")
      end
    end
  end

  describe '#translate' do
    it 'rebuilds the original with the translated text' do
      expect(translation("{s1}\nHallo **John**,\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}."))
        .to eq('<p>Hallo <strong>John</strong>,</p><p>lies <a href="https://example.com/doc">die Anleitung</a> und starte <code>vpn</code>.</p>')
    end

    it 'accepts markers moved with the word order' do
      expect(translation("{s1}\nHallo **John**,\n{s2}\n{2/} starten und {1}die Anleitung{/1} lesen."))
        .to include('<p><code>vpn</code> starten und <a href="https://example.com/doc">die Anleitung</a> lesen.</p>')
    end

    it 'accepts emphasis moved or added by the model' do
      expect(translation("{s1}\nHallo *John*,\n{s2}\n**lies** {1}die *Anleitung*{/1} und starte {2/}."))
        .to include('<p>Hallo <em>John</em>,</p><p><strong>lies</strong> <a href="https://example.com/doc">die <em>Anleitung</em></a>')
    end

    it 'accepts blank lines and whitespace around the sections' do
      expect(translation("\n{s1}\nHallo **John**,\n\n  {s2}  \nlies {1}die Anleitung{/1} und starte {2/}.\n"))
        .to start_with('<p>Hallo <strong>John</strong>,</p>')
    end

    it 'restores line breaks' do
      expect(translation("{s1}\nHallo\nJohn\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}."))
        .to start_with('<p>Hallo<br>John</p>')
    end

    it 'keeps escaped text and Markdown it does not support as text' do
      expect(translation("{s1}\n\\{s2\\} \\*nicht\\* # `code` [link](x) ![image](y) <b>html</b> &amp;\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}."))
        .to start_with('<p>{s2} *nicht* # `code` [link](x) ![image](y) &lt;b&gt;html&lt;/b&gt; &amp;amp;</p>')
    end

    it 'reads emphasis after multibyte characters' do
      expect(translation("{s1}\nfür die **12 Konten** am *Montag*\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}."))
        .to start_with('<p>für die <strong>12 Konten</strong> am <em>Montag</em></p>')
    end

    it 'keeps asterisks that do not enclose a phrase as text' do
      expect(translation("{s1}\n2 * 3, **offen und *allein _nicht_\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}."))
        .to start_with('<p>2 * 3, **offen und *allein _nicht_</p>')
    end

    it 'keeps a line that looks like a list or a heading as text' do
      expect(translation("{s1}\n- Hallo\n# John\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}."))
        .to start_with('<p>- Hallo<br># John</p>')
    end

    context 'with a block inside inline content' do
      let(:html) { '<div>Hi <font face="Arial">there<div>Quoted</div>end</font> of mail</div>' }

      it 'keeps the spaces around the sections' do
        expect(translation("{s1}\nHallo\n{s2}\ndort\n{s3}\nZitat\n{s4}\nEnde\n{s5}\nder Mail"))
          .to eq('<div>Hallo <font face="Arial">dort<div>Zitat</div>Ende</font> der Mail</div>')
      end
    end

    context 'with nested markers' do
      let(:html) { '<p>See <a href="https://example.com"><span style="color:red">the</span> guide</a> <i>now</i>.</p>' }

      it 'rebuilds them inside each other' do
        expect(translation("{s1}\nSiehe {1}{2}die{/2} Anleitung{/1} *jetzt*."))
          .to eq('<p>Siehe <a href="https://example.com"><span style="color:red">die</span> Anleitung</a> <em>jetzt</em>.</p>')
      end

      it 'renders a marker moved out of its parent with simplified formatting' do
        expect(translation("{s1}\nSiehe {1}Anleitung{/1} {2}die{/2} *jetzt*."))
          .to eq('<div>Siehe Anleitung die jetzt.</div><div><a href="https://example.com">https://example.com</a></div>')
      end
    end

    context 'when the answer cannot be rebuilt' do
      {
        'a missing section'           => "{s1}\nHallo **John**,\nlies {1}die Anleitung{/1} und starte {2/}.",
        'reordered sections'          => "{s2}\nlies {1}die Anleitung{/1} und starte {2/}.\n{s1}\nHallo **John**,",
        'a duplicate section'         => "{s1}\nHallo **John**,\n{s1}\nHallo\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}.",
        'text before the first'       => "Sure!\n{s1}\nHallo **John**,\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}.",
        'a missing marker'            => "{s1}\nHallo **John**,\n{s2}\nlies die Anleitung und starte {2/}.",
        'a duplicate marker'          => "{s1}\nHallo **John**,\n{s2}\nlies {1}die{/1} {1}Anleitung{/1} und starte {2/}.",
        'an unknown marker'           => "{s1}\nHallo **John**,\n{s2}\nlies {1}die Anleitung{/1} und starte {2/} {3/}.",
        'a marker of the wrong type'  => "{s1}\nHallo **John**,\n{s2}\nlies {1/} die Anleitung und starte {2/}.",
        'an unclosed marker'          => "{s1}\nHallo **John**,\n{s2}\nlies {1}die Anleitung und starte {2/}.",
        'emphasis crossing a marker'  => "{s1}\nHallo **John**,\n{s2}\nlies **die {1}Anleitung** und{/1} starte {2/}.",
        'an unescaped brace'          => "{s1}\nHallo **John** {,\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}.",
        'a section with markers only' => "{s1}\n{1/}\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}.",
      }.each do |description, response|
        context "with #{description}" do
          it 'renders it with simplified formatting' do
            expect(translation(response)).to start_with('<div>')
          end
        end
      end
    end

    describe 'repairs' do
      {
        'whitespace in a marker'       => 'lies { 1 }die Anleitung{/ 1} und starte {2 /}.',
        'byte tokens in a marker'      => 'lies {<0xA0>1}die Anleitung{/1<0x20>} und starte {2/}.',
        'a dollar for the slash'       => 'lies {1}die Anleitung{$1} und starte {2/}.',
        'a missing opening brace'      => 'lies {1}die Anleitung/1} und starte {2/}.',
        'whitespace in a section mark' => nil,
      }.each do |description, section|
        context "with #{description}" do
          let(:response) { section ? "{s1}\nHallo **John**,\n{s2}\n#{section}" : "{ s1 }\nHallo **John**,\n{s2 }\nlies {1}die Anleitung{/1} und starte {2/}." }

          it 'rebuilds the original' do
            expect(translation(response)).to end_with('<p>lies <a href="https://example.com/doc">die Anleitung</a> und starte <code>vpn</code>.</p>')
          end
        end
      end

      context 'with a span closed twice' do
        let(:html) { '<p><span style="color:red">Red</span> and <a href="https://example.com">link</a></p>' }

        it 'drops the redundant closing' do
          expect(translation("{s1}\n{1}Rot{/1}{/1} und {2}Link{/2}"))
            .to eq('<p><span style="color:red">Rot</span> und <a href="https://example.com">Link</a></p>')
        end

        it 'does not guess where a link ends' do
          expect(translation("{s1}\n{1}Rot{/1} und {2}Link{/2} hier{/2}")).to start_with('<div>Rot und Link hier</div>')
        end
      end

      context 'with marker-like text in the original' do
        let(:html) { '<p>Keep { 1 } and a/1} as they are, <a href="https://example.com">link</a>.</p>' }

        it 'keeps the escaped text' do
          expect(translation("{s1}\nBehalte \\{ 1 \\} und a/1\\} so, {1}Link{/1}."))
            .to eq('<p>Behalte { 1 } und a/1} so, <a href="https://example.com">Link</a>.</p>')
        end
      end
    end

    it 'raises a transformation error for an unexpected failure' do
      allow_any_instance_of(ContentTranslation::Html::Section).to receive(:replace).and_raise(ArgumentError)

      expect { translation("{s1}\nHallo **John**,\n{s2}\nlies {1}die Anleitung{/1} und starte {2/}.") }
        .to raise_error(described_class::TransformationError)
    end
  end

  # Emphasis and markers nested at random, with punctuation next to them: an identity answer has to
  # come back with every character in the same formatting.
  describe 'randomly nested formatting' do
    let(:random) { Random.new(4711) }

    def nested(depth)
      return ['read', 'the', '(guide)', '"quote"', 'word,', 'now.', '2*3', 'über'].sample(random:) if depth.zero? || [true, false, false].sample(random:)

      content = Array.new([1, 2, 3].sample(random:)) { nested(depth - 1) }.join([' ', ''].sample(random:))
      format(['<b>%s</b>', '<i>%s</i>', '<a href="https://example.com">%s</a>', '<span style="color:red">%s</span>', '%s'].sample(random:), content)
    end

    def formatting(html)
      kinds = { 'b' => :bold, 'strong' => :bold, 'i' => :italic, 'em' => :italic, 'a' => :link, 'span' => :span }
      walk  = lambda do |node, active|
        next node.content.gsub(%r{[[:space:]]}, '').chars.map { |character| [character, active] } if node.text?

        node.children.flat_map { |child| walk.call(child, kinds[node.name] ? (active | [kinds[node.name]]).sort : active) }
      end

      walk.call(Nokogiri::HTML5.fragment(html), [])
    end

    it 'rebuilds all of it' do
      sources = Array.new(300) { "<p>start #{nested(4)} end</p>" }

      expect(sources.reject { |source| formatting(described_class.new(source).then { |document| document.translate(document.to_s) }) == formatting(source) })
        .to be_empty
    end
  end

  # Real-world shaped emails (Outlook and Word, with quoted history, signatures, tables and logs),
  # replayed without a provider: an identity answer has to rebuild the original, and a damaged one
  # has to keep every resource of it.
  describe 'the email corpus' do
    Rails.root.glob('spec/fixtures/files/content_translation/*.html').each do |path|
      context "with #{path.basename}" do
        let(:html)     { path.read }
        let(:original) { Nokogiri::HTML5.fragment(html) }

        def resources(fragment)
          {
            links:     fragment.css('a[href]').pluck('href'),
            images:    fragment.css('img').pluck('src'),
            protected: fragment.css('pre, code').map(&:text),
          }
        end

        def text(fragment)
          fragment.text.gsub(%r{[[:space:]]+}, ' ').strip
        end

        it 'sends substantially less than the HTML' do
          expect(described_class.new(html).to_s.bytesize).to be < (html.bytesize * 0.65)
        end

        it 'rebuilds the text and the resources of the original from an identity answer' do
          document = described_class.new(html)
          rebuilt  = Nokogiri::HTML5.fragment(document.translate(document.to_s))

          expect([text(rebuilt), resources(rebuilt)]).to eq([text(original), resources(original)])
        end

        it 'keeps every resource of the original when a section marker was lost' do
          document = described_class.new(html)
          rendered = Nokogiri::HTML5.fragment(document.translate(document.to_s.sub("{s2}\n", '')))

          expect(resources(rendered).transform_values(&:uniq)).to eq(resources(original).transform_values(&:uniq))
        end
      end
    end
  end
end
