# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HtmlSanitizer::Strict, :aggregate_failures do
  def sanitize(input, external: false)
    described_class.new.sanitize(input, external: external, timeout: false)
  end

  describe('#sanitize') do
    it 'performs various XSS checks' do # rubocop:disable RSpec/ExampleLength
      expect(sanitize('<div class="to-be-removed">test</div><script>alert();</script>')).to eq('<div>test</div>')
      expect(sanitize('<b>123</b>')).to eq('<b>123</b>')
      expect(sanitize('<script><b>123</b></script>')).to eq('')
      expect(sanitize('<script><style><b>123</b></style></script>')).to eq('')
      expect(sanitize('<abc><i><b>123</b><bbb>123</bbb></i></abc>')).to eq('<i><b>123</b>123</i>')
      expect(sanitize('<abc><i><b>123</b><bbb>123<i><ccc>abc</ccc></i></bbb></i></abc>')).to eq('<i><b>123</b>123<i>abc</i></i>')
      expect(sanitize('<not_existing>123</not_existing>')).to eq('123')
      expect(sanitize('<script type="text/javascript">alert("XSS!");</script>')).to eq('')
      expect(sanitize('<SCRIPT SRC=http://xss.rocks/xss.js></SCRIPT>')).to eq('')
      expect(sanitize('<IMG SRC="javascript:alert(\'XSS\');">')).to eq('')
      expect(sanitize('<IMG SRC=javascript:alert(\'XSS\')>')).to eq('')
      expect(sanitize('<IMG SRC=JaVaScRiPt:alert(\'XSS\')>')).to eq('')
      expect(sanitize('<IMG SRC=`javascript:alert("RSnake says, \'XSS\'")`>')).to eq('')
      expect(sanitize('<IMG """><SCRIPT>alert("XSS")</SCRIPT>">')).to eq('<img>"&gt;')
      expect(sanitize('<IMG SRC=# onmouseover="alert(\'xxs\')">')).to eq('<img src="#">')
      expect(sanitize('<IMG SRC="jav  ascript:alert(\'XSS\');">')).to eq('')
      expect(sanitize('<IMG SRC="jav&#x09;ascript:alert(\'XSS\');">')).to eq('')
      expect(sanitize('<IMG SRC="jav&#x0A;ascript:alert(\'XSS\');">')).to eq('')
      expect(sanitize('<IMG SRC="jav&#x0D;ascript:alert(\'XSS\');">')).to eq('')
      expect(sanitize('<IMG SRC=" &#14;  javascript:alert(\'XSS\');">')).to eq('<img src="">')
      expect(sanitize('<SCRIPT/XSS SRC="http://xss.rocks/xss.js"></SCRIPT>')).to eq('')
      expect(sanitize('<BODY onload!#$%&()*~+-_.,:;?@[/|\]^`=alert("XSS")>')).to eq('')
      expect(sanitize('<SCRIPT/SRC="http://xss.rocks/xss.js"></SCRIPT>')).to eq('')
      expect(sanitize('<<SCRIPT>alert("XSS");//<</SCRIPT>')).to eq('&lt;')
      expect(sanitize('<SCRIPT SRC=http://xss.rocks/xss.js?< B >')).to eq('')
      expect(sanitize('<SCRIPT SRC=//xss.rocks/.j>')).to eq('')
      expect(sanitize('<IMG SRC="javascript:alert(\'XSS\')"')).to eq('')
      expect(sanitize('<IMG SRC="javascript:alert(\'XSS\')" abc<b>123</b>')).to eq('123')
      expect(sanitize('<iframe src=http://xss.rocks/scriptlet.html <')).to eq('')
      expect(sanitize('</script><script>alert(\'XSS\');</script>')).to eq('')
      expect(sanitize('<STYLE>li {list-style-image: url("javascript:alert(\'XSS\')");}</STYLE><UL><LI>XSS</br>')).to eq('<ul><li>XSS</li></ul>')
      expect(sanitize('<IMG SRC=\'vbscript:msgbox("XSS")\'>')).to eq('')
      expect(sanitize('<IMG SRC="livescript:[code]">')).to eq('')
      expect(sanitize('<svg/onload=alert(\'XSS\')>')).to eq('')
      expect(sanitize('<BODY ONLOAD=alert(\'XSS\')>')).to eq('')
      expect(sanitize('<LINK REL="stylesheet" HREF="javascript:alert(\'XSS\');">')).to eq('')
      expect(sanitize('<STYLE>@import\'http://xss.rocks/xss.css\';</STYLE>')).to eq('')
      expect(sanitize('<META HTTP-EQUIV="Link" Content="<http://xss.rocks/xss.css>; REL=stylesheet">')).to eq('')
      expect(sanitize('<IMG STYLE="java/*XSS*/script:(alert(\'XSS\'), \'\')">')).to eq('<img>')
      expect(sanitize('<IMG src="java/*XSS*/script:(alert(\'XSS\'), \'\')">')).to eq('')
      expect(sanitize('<IFRAME SRC="javascript:alert(\'XSS\');"></IFRAME>')).to eq('')
      expect(sanitize('<TABLE><TD BACKGROUND="javascript:alert(\'XSS\')">')).to eq('<table><td></td></table>')
      expect(sanitize('<DIV STYLE="background-image: url(javascript:alert(\'XSS\'), \'\')">')).to eq('<div></div>')
      expect(sanitize('<a href="/some/path">test</a>')).to eq('<a href="/some/path">test</a>')
      expect(sanitize('<a href="https://some/path">test</a>')).to eq('<a href="https://some/path" rel="nofollow noreferrer noopener" target="_blank" title="https://some/path">test</a>')
      expect(sanitize('<a href="https://some/path">test</a>', external: true)).to eq('<a href="https://some/path" rel="nofollow noreferrer noopener" target="_blank" title="https://some/path">test</a>')
      expect(sanitize('<XML ID="xss"><I><B><IMG SRC="javas<!-- -->cript:alert(\'XSS\')"></B></I></XML>')).to eq('<i><b></b></i>')
      expect(sanitize('<IMG SRC="javas<!-- -->cript:alert(\'XSS\')">')).to eq('')
      expect(sanitize(' <HEAD><META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=UTF-7"> </HEAD>+ADw-SCRIPT+AD4-alert(\'XSS\');+ADw-/SCRIPT+AD4-')).to eq('  +ADw-SCRIPT+AD4-alert(\'XSS\');+ADw-/SCRIPT+AD4-')
      expect(sanitize('<SCRIPT a=">" SRC="httx://xss.rocks/xss.js"></SCRIPT>')).to eq('')
      expect(sanitize("<A HREF=\"h\ntt  p://6 6.000146.0x7.147/\">XSS</A>")).to eq('<a href="h%0Att%20%20p://6%206.000146.0x7.147/" rel="nofollow noreferrer noopener" target="_blank" title="h%0Att%20%20p://6%206.000146.0x7.147/">XSS</a>')
      expect(sanitize("<A HREF=\"h\ntt  p://6 6.000146.0x7.147/\">XSS</A>", external: true)).to eq('<a href="http://h%0Att%20%20p://6%206.000146.0x7.147/" rel="nofollow noreferrer noopener" target="_blank" title="http://h%0Att%20%20p://6%206.000146.0x7.147/">XSS</a>')
      expect(sanitize('<A HREF="//www.google.com/">XSS</A>')).to eq('<a href="//www.google.com/" rel="nofollow noreferrer noopener" target="_blank" title="//www.google.com/">XSS</a>')
      expect(sanitize('<A HREF="//www.google.com/">XSS</A>', external: true)).to eq('<a href="//www.google.com/" rel="nofollow noreferrer noopener" target="_blank" title="//www.google.com/">XSS</a>')
      expect(sanitize('<form id="test"></form><button form="test" formaction="javascript:alert(1)">X</button>')).to eq('X')
      expect(sanitize('<maction actiontype="statusline#http://google.com" xlink:href="javascript:alert(2)">CLICKME</maction>')).to eq('CLICKME')
      expect(sanitize('<a xlink:href="javascript:alert(2)">CLICKME</a>')).to eq('CLICKME')
      expect(sanitize('<a xlink:href="javascript:alert(2)">CLICKME</a>', external: true)).to eq('CLICKME')
      expect(sanitize('<!--<img src="--><img src=x onerror=alert(1)//">')).to eq('<img src="x">')
      expect(sanitize('<![><img src="]><img src=x onerror=alert(1)//">')).to eq('<img src="]&gt;&lt;img%20src=x%20onerror=alert(1)//">')
      expect(sanitize('<svg><![CDATA[><image xlink:href="]]><img src=xx:x onerror=alert(2)//"></svg>')).to eq('')
      expect(sanitize('<abc><img src="</abc><img src=x onerror=alert(1)//">')).to eq('<img src="&lt;/abc&gt;&lt;img%20src=x%20onerror=alert(1)//">')
      expect(sanitize('<object data="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="></object>')).to eq('')
      expect(sanitize('<embed src="data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="></embed>')).to eq('')
      expect(sanitize('<img[a][b]src=x[d]onerror[c]=[e]"alert(1)">')).to eq('<img>')
      expect(sanitize('<a href="[a]java[b]script[c]:alert(1)">XXX</a>')).to eq('<a href="[a]java[b]script[c]:alert(1)">XXX</a>')
      expect(sanitize('<a href="[a]java[b]script[c]:alert(1)">XXX</a>', external: true)).to eq('<a href="http://[a]java[b]script[c]:alert(1)" rel="nofollow noreferrer noopener" target="_blank" title="http://[a]java[b]script[c]:alert(1)">XXX</a>')
      expect(sanitize('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>')).to eq('')
    end

    it 'performs style cleanups' do
      expect(sanitize('<a style="position:fixed;top:0;left:0;width: 260px;height:100vh;background-color:red;display: block;" href="http://example.com"></a>')).to eq('<a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com"></a>')
      expect(sanitize('<a style="position:fixed;top:0;left:0;width: 260px;height:100vh;background-color:red;display: block;" href="http://example.com"></a>', external: true)).to eq('<a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com"></a>')
      expect(sanitize('<table><tr style="font-size: 0"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size: 0px"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size: 0pt"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size:0"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-Size:0px"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size:0em"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style=" Font-size:0%"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size:0%;display: none;"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size:0%;visibility:hidden;"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<table><tr style="font-size:0%;visibility:hidden;"><td>123</td></tr></table>')).to eq('<table><tr><td>123</td></tr></table>')
      expect(sanitize('<html><body><div style="font-family: Meiryo, メイリオ, &quot;Hiragino Sans&quot;, sans-serif; font-size: 12pt; color: rgb(0, 0, 0);">このアドレスへのメルマガを解除してください。</div></body></html>')).to eq('<div>このアドレスへのメルマガを解除してください。</div>')
    end

    context 'when performing multiline style cleanup' do
      let(:input) { <<~INPUT }
        <div>
        <style type="text/css">#outlook A {
        .content { WIDTH: 100%; MAX-WIDTH: 740px }
        A { COLOR: #666666; TEXT-DECORATION: none }
        A:link { COLOR: #666666; TEXT-DECORATION: none }
        A:hover { COLOR: #666666; TEXT-DECORATION: none }
        A:active { COLOR: #666666; TEXT-DECORATION: none }
        A:focus { COLOR: #666666; TEXT-DECORATION: none }
        BODY { FONT-FAMILY: Calibri, Arial, Verdana, sans-serif }
        </style>
        <!--[if (gte mso 9)|(IE)]>
        <META name=GENERATOR content="MSHTML 9.00.8112.16800"></HEAD>
        <BODY bgColor=#ffffff>
        <DIV><FONT size=2 face=Arial></FONT>&nbsp;</DIV>
        <BLOCKQUOTE
        style="BORDER-LEFT: #000000 2px solid; PADDING-LEFT: 5px; PADDING-RIGHT: 0px; MARGIN-LEFT: 5px; MARGIN-RIGHT: 0px">
          <DIV style="FONT: 10pt arial">----- Original Message ----- </DIV>
          <DIV style="FONT: 10pt arial"><B>To:</B> <A title=smith.test@example.dk
          href="mailto:smith.test@example.dk">smith.test@example.dk</A> </DIV>
          <DIV style="FONT: 10pt arial"><B>Sent:</B> Friday, November 10, 2017 9:11
          PM</DIV>
          <DIV style="FONT: 10pt arial"><B>Subject:</B> Din bestilling hos
          example.dk - M123 - KD1234</DIV>
          <div>&nbsp;</div>
        <![endif]-->test 123
        <blockquote></div>
      INPUT
      let(:output) { <<~OUTPUT }

        <div>

        test 123
        <blockquote></blockquote>
        </div>
      OUTPUT

      it 'filters correctly' do
        expect(sanitize(input)).to eq(output)
      end
    end

    context 'when performing more multiline style cleanup' do
      let(:input) { <<~INPUT }
        <style><!--
        /* Font Definitions */
        @font-face
          {font-family:"Cambria Math";
          panose-1:2 4 5 3 5 4 6 3 2 4;}
          {page:WordSection1;}</style><!--[if gte mso 9]><xml>
        <o:shapedefaults v:ext="edit" spidmax="1026" />
        </xml><![endif]--><!--[if gte mso 9]><xml>
        <o:shapelayout v:ext="edit">
        <o:idmap v:ext="edit" data="1" />
        </o:shapelayout></xml><![endif]-->
        <div>123</div>
        <a href="#DAB4FAD8-2DD7-40BB-A1B8-4E2AA1F9FDF2" width="1" height="1">abc</a></div>
      INPUT
      let(:output) { <<~OUTPUT }

        <div>123</div>
        <a href="#DAB4FAD8-2DD7-40BB-A1B8-4E2AA1F9FDF2">abc</a>
      OUTPUT

      it 'filters correctly' do
        expect(sanitize(input)).to eq(output)
      end
    end

    it 'handles mailto: links' do
      expect(sanitize('<a href="mailto:testäöü@example.com" id="123">test</a>')).to eq('<a href="mailto:test%C3%A4%C3%B6%C3%BC@example.com">test</a>')
    end

    context 'when handling code blocks' do
      let(:input) { <<~INPUT }
              <pre><code>apt-get update
        Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
        Hit:2 http://de.archive.ubuntu.com/ubuntu focal InRelease
        Hit:3 http://de.archive.ubuntu.com/ubuntu focal-updates InRelease
        Get:4 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ InR=
        elease [3820 B]
        Hit:5 http://de.archive.ubuntu.com/ubuntu focal-backports InRelease
        Get:6 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ InRelease [3781 =
        B]
        Get:7 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Sou=
        rces [2710 B]
        Get:8 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Pac=
        kages [6507 B]
        Get:9 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Sources [9066 B]
        Get:10 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Packages [23.8 =
        kB]
        Get:11 http://security.ubuntu.com/ubuntu focal-security/main amd64 DEP-11 M=
        etadata [40.6 kB]
        Get:12 http://security.ubuntu.com/ubuntu focal-security/universe amd64 DEP-=
        11 Metadata [66.3 kB]
        Get:13 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 DE=
        P-11 Metadata [2464 B]
        Fetched 273 kB in 1s (288 kB/s)
        Reading package lists...
        Batterie-Status pr&uuml;fen
        Reading package lists...
        Building dependency tree...</code></pre>
      INPUT

      let(:output) { <<~OUTPUT }
              <pre><code>apt-get update
        Get:1 http://security.ubuntu.com/ubuntu focal-security InRelease [114 kB]
        Hit:2 http://de.archive.ubuntu.com/ubuntu focal InRelease
        Hit:3 http://de.archive.ubuntu.com/ubuntu focal-updates InRelease
        Get:4 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ InR=
        elease [3820 B]
        Hit:5 http://de.archive.ubuntu.com/ubuntu focal-backports InRelease
        Get:6 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ InRelease [3781 =
        B]
        Get:7 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Sou=
        rces [2710 B]
        Get:8 http://10.10.21.205:3207/dprepo/ubuntu experimental/20.04_x86_64/ Pac=
        kages [6507 B]
        Get:9 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Sources [9066 B]
        Get:10 http://10.10.21.205:3207/dprepo/ubuntu 20.04_x86_64/ Packages [23.8 =
        kB]
        Get:11 http://security.ubuntu.com/ubuntu focal-security/main amd64 DEP-11 M=
        etadata [40.6 kB]
        Get:12 http://security.ubuntu.com/ubuntu focal-security/universe amd64 DEP-=
        11 Metadata [66.3 kB]
        Get:13 http://security.ubuntu.com/ubuntu focal-security/multiverse amd64 DE=
        P-11 Metadata [2464 B]
        Fetched 273 kB in 1s (288 kB/s)
        Reading package lists...
        Batterie-Status prüfen
        Reading package lists...
        Building dependency tree...</code></pre>
      OUTPUT

      it 'handles code blocks correctly' do
        expect(sanitize(input)).to eq(output)
      end
    end

    context 'when checking attachment URLs' do
      let(:api_path)                  { Rails.configuration.api_path }
      let(:http_type)                 { Setting.get('http_type') }
      let(:fqdn)                      { Setting.get('fqdn') }
      let(:attachment_url)            { "#{http_type}://#{fqdn}#{api_path}/ticket_attachment/239/986/1653" }
      let(:attachment_url_good)       { "#{attachment_url}?disposition=attachment" }
      let(:attachment_url_evil)       { "#{attachment_url}?disposition=inline" }
      let(:different_fqdn_url)        { attachment_url_evil.gsub(fqdn, 'some.other.tld') }
      let(:attachment_url_evil_other) { "#{attachment_url}?disposition=some_other" }

      it 'handles attachment URLs correctly' do
        expect(sanitize('<a href="/some/path%20test.pdf">test</a>')).to eq('<a href="/some/path%20test.pdf">test</a>')
        expect(sanitize('<a href="https://somehost.domain/path%20test.pdf">test</a>')).to eq('<a href="https://somehost.domain/path%20test.pdf" rel="nofollow noreferrer noopener" target="_blank" title="https://somehost.domain/path%20test.pdf">test</a>')
        expect(sanitize('<a href="https://somehost.domain/zaihan%20test">test</a>')).to eq('<a href="https://somehost.domain/zaihan%20test" rel="nofollow noreferrer noopener" target="_blank" title="https://somehost.domain/zaihan%20test">test</a>')
        expect(sanitize("<a href=\"#{attachment_url_evil}\">Evil link</a>")).to eq("<a href=\"#{attachment_url_good}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url_good}\">Evil link</a>")
        expect(sanitize("<a href=\"#{attachment_url_good}\">Good link</a>")).to eq("<a href=\"#{attachment_url_good}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url_good}\">Good link</a>")
        expect(sanitize("<a href=\"#{attachment_url}\">No disposition</a>")).to eq("<a href=\"#{attachment_url}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url}\">No disposition</a>")
        expect(sanitize("<a href=\"#{different_fqdn_url}\">Different FQDN</a>")).to eq("<a href=\"#{different_fqdn_url}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{different_fqdn_url}\">Different FQDN</a>")
        expect(sanitize("<a href=\"#{attachment_url_evil_other}\">Evil link</a>")).to eq("<a href=\"#{attachment_url_good}\" rel=\"nofollow noreferrer noopener\" target=\"_blank\" title=\"#{attachment_url_good}\">Evil link</a>")
      end
    end
  end
end
