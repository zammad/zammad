# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ContentTranslation::Html::Fallback do
  subject(:rendered) { described_class.new(response, Loofah.html5_fragment(html)).render }

  let(:html)     { '<p>Hello</p>' }
  let(:response) { "{s1}\nHallo **John**,\nwie {1}geht's{/1}? {2/}\n{s2}\n\\*Nicht\\* fett \\{1\\}." }

  it 'renders the text as prose, a paragraph per section' do
    expect(rendered).to eq('<div>Hallo John,<br>wie geht&#39;s?</div><div>*Nicht* fett {1}.</div>')
  end

  context 'with asterisks that are not formatting' do
    let(:response) { "{s1}\n2 * 3 = 6, Karte ****1234, **fett**" }

    it 'keeps them' do
      expect(rendered).to eq('<div>2 * 3 = 6, Karte ****1234, fett</div>')
    end
  end

  context 'with a stray brace in the answer' do
    let(:response) { "{s1}\nHallo { **Welt** 2 * 3" }

    it 'renders the text without the formatting' do
      expect(rendered).to eq('<div>Hallo { Welt 2  3</div>')
    end
  end

  context 'with HTML in the answer' do
    let(:response) { "{s1}\n<script>alert(1)</script><b>Hallo</b>" }

    it 'renders it as text' do
      expect(rendered).to eq('<div>&lt;script&gt;alert(1)&lt;/script&gt;&lt;b&gt;Hallo&lt;/b&gt;</div>')
    end
  end

  context 'with section markers on the line of their text' do
    let(:response) { "{s1} Hallo\n{s2} Welt **x**" }

    it 'drops them like the ones on their own line' do
      expect(rendered).to eq('<div>Hallo</div><div>Welt x</div>')
    end
  end

  context 'with escaped markers in the text' do
    let(:response) { "{s1}\nSiehe \\{s1} und \\{s2\\}, \\{1} und \\{/2}" }

    it 'keeps them as text' do
      expect(rendered).to eq('<div>Siehe {s1} und {s2}, {1} und {/2}</div>')
    end
  end

  context 'with an answer without section markers' do
    let(:response) { "Hallo\n\nWelt" }

    it 'renders all of it' do
      expect(rendered).to eq('<div>Hallo<br><br>Welt</div>')
    end
  end

  context 'with resources in the original' do
    let(:html) do
      <<~HTML
        <p>See <a href="https://example.com/a">A</a>, <a href="https://example.com/a">A again</a> and <a name="anchor">no link</a>.</p>
        <p><a href="https://example.com/b"><img src="cid:logo" alt="Logo"></a></p>
        <pre><code>ls -la</code></pre>
        <p>Run <code>make</code> in <span translate="no">Zammad</span> <span translate="yes">translated</span>.</p>
      HTML
    end

    it 'lists the links, images and protected content of the original after the text' do
      expect(rendered).to end_with(
        '<div><a href="https://example.com/a">https://example.com/a</a></div>' \
        '<div><a href="https://example.com/b">https://example.com/b</a></div>' \
        '<div><img src="cid:logo" alt="Logo"></div>' \
        '<div><pre><code>ls -la</code></pre></div>' \
        '<div><code>make</code></div>' \
        '<div><span translate="no">Zammad</span></div>'
      )
    end
  end

  context 'with an answer without text' do
    let(:response) { "{s1}\n{1/} **\n{s2}\n" }

    it 'renders nothing' do
      expect(rendered).to be_nil
    end
  end

  context 'with an answer that is not text' do
    let(:response) { { 'translation' => 'Hallo' } }

    it 'renders nothing' do
      expect(rendered).to be_nil
    end
  end
end
