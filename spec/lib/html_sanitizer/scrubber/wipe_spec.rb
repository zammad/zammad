# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Scrubber::Wipe do
  let(:scrubber) { described_class.new }

  describe('#scrubber') do
    subject(:actual) do
      # export with extra options to avoid html indentation
      fragment.scrub!(scrubber)
        .to_html save_with: Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^ Nokogiri::XML::Node::SaveOptions::FORMAT
    end

    let(:fragment) { Loofah.html5_fragment(input) }

    context 'when has not allowed tag' do
      let(:input)  { '<not-allowed><b>asd</b></not-allowed>' }
      let(:target) { '<b>asd</b>' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed tag in not allowed' do
      let(:input)  { '<not-allowed><not-allowed>asd</not-allowed></not-allowed>' }
      let(:target) { 'asd' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed tag inside of an allowed tag' do
      let(:input)  { '<div><not-allowed></not-allowed></div>' }
      let(:target) { '<div></div>' }

      it { is_expected.to eq target }
    end

    context 'when insecure source' do
      let(:input)  { '<img src="http://example.org/image.jpg">' }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed classes' do
      let(:input)  { '<div class="to-be-removed js-signatureMarker">test</div>' }
      let(:target) { '<div class="js-signatureMarker">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has width and height attributes' do
      let(:input)  { '<img width="100px" height="100px" other="true">' }
      let(:target) { '<img style="width:100px;height:100px;">' }

      it { is_expected.to eq target }
    end

    context 'when has width and max-width attributes' do
      let(:input)  { '<img width="100px" style="max-width: 600px">' }
      let(:target) { '<img style="max-width: 600px;width:100px;">' }

      it { is_expected.to eq target }
    end

    context 'when has not allowed attributes' do
      let(:input)  { '<div width="100px" style="color:#ff0000" other="true">test</div>' }
      let(:target) { '<div style="color:#ff0000;">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has style' do
      let(:input)  { '<div style="color:white">test</div><div style="color:#ff0000;">test</div>' }
      let(:target) { '<div>test</div><div style="color:#ff0000;">test</div>' }

      it { is_expected.to eq target }
    end

    context 'when has executeable link' do
      let(:input)  { '<img style="width:100%" src="javascript:alert()">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when href contains javascript: scheme' do
      let(:input)  { '<a href="javascript:alert()">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when href contains data: scheme' do
      let(:input)  { '<a href="data:text/html,<h1>XSS</h1>">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when href contains data: scheme with javascript' do
      let(:input)  { '<a href="data:text/javascript,alert(1)">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when href contains data: scheme uppercased' do
      let(:input)  { '<a href="DATA:text/html,<b>test</b>">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when style contains data: scheme' do
      let(:input)  { '<a style="data:text/html,something">click</a>' }
      let(:target) { '<a>click</a>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a remote url' do
      let(:input)  { '<span style="background:url(https://attacker.example/p.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a quoted remote url' do
      let(:input)  { %(<span style='background: url( "https://attacker.example/p.gif" )'>x</span>) }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a protocol-relative api url of the own host' do
      let(:input)  { "<table><tr><td style=\"background:url(//#{Setting.get('fqdn')}/api/v1/signout)\">x</td></tr></table>" }
      let(:target) { '<table><tbody><tr><td>x</td></tr></tbody></table>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a relative api path' do
      let(:input)  { '<span style="background:url(/api/v1/signout)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style background contains a url starting with css-escaped backslashes' do
      let(:input)  { '<span style="background:url(\\5c\\5c attacker.example/b.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a quoted url starting with a slash and a css-escaped backslash' do
      let(:input)  { %(<span style='background:url("/\\5c attacker.example/b.gif")'>x</span>) }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a url starting with a single css-escaped backslash' do
      let(:input)  { '<span style="background:url(\\5c attacker.example/b.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style background contains a url with a css-escaped tab between its leading slashes' do
      let(:input)  { '<span style="background:url(/\\9/attacker.example/t.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a quoted url preceded by a css-escaped control character' do
      let(:input)  { %(<span style='background:url("\\1 //attacker.example/c.gif")'>x</span>) }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a css-escaped url' do
      let(:input)  { '<span style="background:u\\72l(https://attacker.example/e.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a css-escaped url followed by whitespace' do
      let(:input)  { '<span style="background:\\75 rl(https://attacker.example/e.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a six-digit css-escaped url' do
      let(:input)  { '<span style="background:u\\000072l(https://attacker.example/e.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a comment between url and its argument' do
      let(:input)  { '<span style="background:url/**/(https://attacker.example/c.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a comment inside the url function name' do
      let(:input)  { '<span style="background:u/**/rl(https://attacker.example/c.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a comment spanning declarations between url and its argument' do
      let(:input)  { '<span style="background:url/*;background:*/(https://attacker.example/c.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style contains a comment spanning declarations inside the url function name' do
      let(:input)  { '<span style="background:u/*;color:*/rl(https://attacker.example/c.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style contains a comment whose end is in a removed declaration' do
      let(:input)  { '<span style="color:red/*;position:fixed*/;background:url/*;color:*/(https://attacker.example/c.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style contains a comment inside a declaration' do
      let(:input)  { '<span style="color:/* text */red;background-color:#ff0000">x</span>' }
      let(:target) { '<span style="color:/* text */red;background-color:#ff0000;">x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style of a not allowed property contains a remote url' do
      let(:input)  { '<div style="background:url(https://attacker.example/p.gif)">x</div>' }
      let(:target) { '<div>x</div>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a relative url next to a remote-looking string' do
      let(:input)  { '<span style="background:url(/api/v1/attachments/1) &quot;https://attacker.example/&quot;">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style background contains a relative url next to a remote-looking comment' do
      let(:input)  { '<span style="background:url(/x) /* https://attacker.example/ */">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style color contains a css-escaped blocked value' do
      let(:input)  { '<span style="color:\\77hite">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style color contains a blocked value escaped to uppercase' do
      let(:input)  { '<span style="color:\\57 hite">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains an image-set with a nested url before a remote string' do
      let(:input)  { %(<span style='background:image-set(url(/a.png) 1x, "https://attacker.example/x.png" 2x)'>x</span>) }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an image-set with a parenthesis inside a string' do
      let(:input)  { "<span style='background:image-set(\"a).png\" 1x, \"https://attacker.example/x.png\" 2x)'>x</span>" }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an image-set with an escaped quote inside a string' do
      let(:input)  { %q[<span style='background:image-set("a\")b.png" 1x, "https://attacker.example/x.png" 2x)'>x</span>] }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an escaped image-set with a hex-escaped quote inside a string' do
      let(:input)  { %q[<span style='background:image-s\65t("a\22 )b.png" 1x, "https://attacker.example/x.png" 2x)'>x</span>] }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an image-set with an escaped parenthesis outside a string' do
      let(:input)  { %q[<span style='background:image-set(a\29  1x, "https://attacker.example/x.png" 2x)'>x</span>] }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a url with an escaped parenthesis' do
      let(:input)  { %q[<span style="background:url\28 https://attacker.example/p.gif)">x</span>] }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains an image-set with a nested gradient before a remote string' do
      let(:input)  { %(<span style='background:image-set(linear-gradient(rgb(0,0,0), red) 1x, "https://attacker.example/x.png" 2x)'>x</span>) }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a multi-byte character before a remote url' do
      let(:input)  { '<span style="background:宋体 url(https://attacker.example/m.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an escape resolving to a multi-byte character before a remote url' do
      let(:input)  { '<span style="background:\\e9 url(https://attacker.example/m.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an import of a remote url' do
      let(:input)  { '<span style="background:@import url(https://attacker.example/i.css)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a long run of unbalanced url functions' do
      let(:input)  { "<span style=\"background:#{'url(' * 16_000}\">x</span>" }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a url preceded by a comment' do
      let(:input)  { '<span style="background:/**/url(https://attacker.example/c.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a url after a comment opener inside a string' do
      let(:input)  { %(<span style='background:env(safe-area-inset-top, "/*") url(https://attacker.example/s.gif?*/)'>x</span>) }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains an image-set' do
      let(:input)  { '<span style="background:image-set(\'https://attacker.example/i.gif\' 1x)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains a url next to a background-color' do
      let(:input)  { '<span style="background:url(https://attacker.example/p.gif);background-color:#ff0000">x</span>' }
      let(:target) { '<span style="background-color:#ff0000;">x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a plain colour' do
      let(:input)  { '<span style="background:#ff0000">x</span>' }
      let(:target) { '<span style="background:#ff0000;">x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style background contains a url only inside a comment' do
      let(:input)  { '<span style="background:#fff /* was url(https://cdn.example/bg.png) */">x</span>' }
      let(:target) { '<span style="background:#fff /* was url(https://cdn.example/bg.png) */;">x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style background contains a url after an escaped comment opener' do
      let(:input)  { '<span style="background:\\/* x */url(https://attacker.example/e.gif)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when style background contains colour and gradient functions' do
      let(:input)  { '<span style="background:linear-gradient(rgb(0,0,0), hsl(0 100% 50%))">x</span>' }
      let(:target) { '<span style="background:linear-gradient(rgb(0,0,0), hsl(0 100% 50%));">x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a function that is not known to be safe' do
      let(:input)  { '<span style="background:paint(tracker);background-color:#ff0000">x</span>' }
      let(:target) { '<span style="background-color:#ff0000;">x</span>' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when style background contains an allowed function name with a prefix' do
      let(:input)  { '<span style="background:-x-rgb(0,0,0)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when style background contains a css-escaped function that is not known to be safe' do
      let(:input)  { '<span style="background:v\\61r(--x)">x</span>' }
      let(:target) { '<span>x</span>' }

      it { is_expected.to eq target }
    end

    context 'when has an image with a proper link' do
      let(:input)  { '<img style="width:100%" src="https://zammad.org/dummy.png">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses http: scheme without slashes' do
      let(:input)  { '<img src="http:attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses https: scheme without slashes' do
      let(:input)  { '<img src="https:attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when srcset uses http: scheme without slashes' do
      let(:input)  { '<img srcset="http:attacker.example/pixel.gif 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses backslashes as protocol-relative prefix' do
      let(:input)  { '<img src="\\\\attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses a slash and a backslash as protocol-relative prefix' do
      let(:input)  { '<img src="/\attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses a backslash and a slash as protocol-relative prefix' do
      let(:input)  { '<img src="\/attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src uses backslashes to reach an api endpoint on the own fqdn' do
      let(:input)  { "<img src=\"\\\\#{Setting.get('fqdn')}/api/v1/signout\">" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when srcset uses backslashes as protocol-relative prefix' do
      let(:input)  { '<img srcset="\\\\attacker.example/pixel.gif 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src starts with a control character before a protocol-relative url' do
      let(:input)  { '<img src="&#1;//attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src starts with a control character before a backslash protocol-relative url' do
      let(:input)  { '<img src="&#x1f;\\\\attacker.example/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src starts with a control character before an api endpoint' do
      let(:input)  { '<img src="&#1;/api/v1/signout">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset starts with a control character before a protocol-relative url' do
      let(:input)  { '<img srcset="&#1;//attacker.example/pixel.gif 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when has a remote srcset without src' do
      let(:input)  { '<img srcset="https://tracking.example.com/pixel.gif">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when has a remote srcset with a local src' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="https://tracking.example.com/pixel.gif 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1">' } # srcset should be stripped

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when srcset has only safe sources' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x, /api/v1/attachments/2 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x, /api/v1/attachments/2 2x">' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset has a mix of safe and unsafe sources' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x, https://tracking.example.com/pixel.gif 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x">' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when srcset contains a data: URL with a comma in it' do
      let(:input)  { '<img srcset="data:image/png,abc 1x">' }
      let(:target) { '<img srcset="data:image/png,abc 1x">' }

      it { is_expected.to eq target }
    end

    context 'when srcset has a javascript: URL' do
      let(:input)  { '<img srcset="javascript:alert() 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset candidates are separated by multiple commas with a remote entry' do
      let(:input)  { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x,, https://remote.example.com/track.gif 2x">' }
      let(:target) { '<img src="/api/v1/attachments/1" srcset="/api/v1/attachments/1 1x">' }

      it { is_expected.to eq target }

      it 'does mark remote content as removed' do
        expect { actual }.to change(scrubber, :remote_content_removed).from(false).to(true)
      end
    end

    context 'when src is present but empty' do
      let(:input)  { '<img src="">' }
      let(:target) { '<img src="">' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset is present but empty' do
      let(:input)  { '<img srcset="">' }
      let(:target) { '<img srcset="">' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to signout endpoint' do
      let(:input)  { "<img src='/api/v1/signout'>" }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to sessions switch' do
      let(:input)  { "<img src='/api/v1/sessions/switch/5'>" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when src points to sessions switch back' do
      let(:input)  { "<img src='/api/v1/sessions/switch_back'>" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when src points to auto wizard' do
      let(:input)  { "<img src='/api/v1/getting_started/auto_wizard/token123'>" }
      let(:target) { '' }

      it { is_expected.to eq target }
    end

    context 'when srcset contains an api endpoint candidate' do
      let(:input)  { '<img srcset="/api/v1/signout 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when srcset contains an interior-traversal api path' do
      let(:input)  { '<img srcset="/api/v1/attachments/../signout 1x">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src contains a double-encoded traversal api path' do
      let(:input)  { '<img src="/api/v1/attachments/%252e%252e/signout">' }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is a safe path-absolute URL' do
      let(:input) { "<img src='/assets/images/logo.png'>" }

      it { is_expected.to include('/assets/images/logo.png') }
    end

    context 'when src is a safe relative URL without leading slash' do
      let(:input) { "<img src='images/logo.png'>" }

      it { is_expected.to include('images/logo.png') }
    end

    context 'when src points to allowed content path (ticket attachment)' do
      let(:input) { "<img src='/api/v1/ticket_attachment/1/2/3'>" }

      it { is_expected.to include('/api/v1/ticket_attachment/1/2/3') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to allowed content path (attachment store)' do
      let(:input) { "<img src='/api/v1/attachments/1'>" }

      it { is_expected.to include('/api/v1/attachments/1') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src points to user avatar' do
      let(:input) { "<img src='/users/image/abc123'>" }

      it { is_expected.to include('/users/image/abc123') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is a relative api path without leading slash' do
      let(:input)  { "<img src='api/v1/signout'>" }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is a relative api path with parent dir' do
      let(:input)  { "<img src='../api/v1/signout'>" }
      let(:target) { '' }

      it { is_expected.to eq target }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is attachment store without trailing path' do
      let(:input) { "<img src='/api/v1/attachments'>" }

      it { is_expected.to include('/api/v1/attachments') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end

    context 'when src is authorize (not api/auth)' do
      let(:input) { "<img src='/authorize'>" }

      it { is_expected.to include('/authorize') }

      it 'does not mark remote content as removed' do
        expect { actual }.not_to change(scrubber, :remote_content_removed)
      end
    end
  end

  describe '#remote_url?' do
    subject(:remote) { scrubber.send(:remote_url?, url) }

    {
      # remote urls
      'https://attacker.example/pixel.gif'   => true,
      'http:attacker.example/pixel.gif'      => true,
      '//attacker.example/pixel.gif'         => true,

      # backslash variants browsers resolve like slashes
      '\\\\attacker.example/pixel.gif'       => true,
      '/\attacker.example/pixel.gif'         => true,
      '\/attacker.example/pixel.gif'         => true,
      'https:\\\\attacker.example/pixel.gif' => true,

      # local urls
      '/api/v1/attachments/1'                => false,
      '\api\v1\attachments\1'                => false,
      'images/logo.png'                      => false,
    }.each do |test_url, expected_remote|
      context "with #{test_url.inspect}" do
        let(:url) { test_url }

        it "is #{expected_remote ? 'remote' : 'local'}" do
          expect(remote).to be(expected_remote)
        end
      end
    end
  end

  describe '#unsafe_api_path?' do
    subject(:unsafe) { scrubber.send(:unsafe_api_path?, path) }

    let(:scrubber) { described_class.new }

    {
      # allowlisted api paths
      '/api/v1/attachments/1'                               => false,
      '/api/v1/attachments'                                 => false,
      '/api/v1/ticket_attachment/1/2/3?view=inline'         => false,
      'api/v1/attachments/1'                                => false,

      # blocked api paths
      '/api/v1/attachments_evil'                            => true,
      '/api/v1/ticket_attachment_upload_clone_by_article/1' => true,
      '/api/v1/signout'                                     => true,
      '../api/v1/signout'                                   => true,
      '../api/v1/attachments/'                              => true,
      '../api/v1/attachments/1'                             => true,

      # interior traversal bypass (literal, double-encoded, and backslash separator variants)
      '/api/v1/attachments/../signout'                      => true,
      '/api/v1/attachments/./signout'                       => true,
      '/api/v1/ticket_attachment/../signout'                => true,
      '/api/v1/attachments/%2e%2e/signout'                  => true,
      '/api/v1/attachments/..\signout'                      => true,

      # non-api paths
      '/users/image/abc123'                                 => false,
      '/assets/images/logo.png'                             => false,
    }.each do |test_path, expected_unsafe|
      context "with #{test_path.inspect}" do
        let(:path) { test_path }

        it "is #{expected_unsafe ? 'unsafe' : 'safe'}" do
          expect(unsafe).to be(expected_unsafe)
        end
      end
    end
  end
end
