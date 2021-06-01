# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe String do
  describe '#strip' do
    context 'default behavior' do
      it 'removes leading/trailing spaces' do
        expect(' test  '.strip).to eq('test')
      end

      it 'removes trailing newlines' do
        expect("test\n".strip).to eq('test')
      end

      it 'does not remove internal spaces / newlines' do
        expect("test \n test".strip).to eq("test \n test")
      end
    end

    context 'monkey-patched behavior' do
      it 'removes leading/trailing zero-width spaces, but not internal ones' do
        expect(" \r\n test \u{200B} \n test\u{200B} \u{200B}".strip)
          .to eq("test \u{200B} \n test")
      end

      it 'does not break on non-unicode strings' do
        expect(described_class.new("\xC2\xA92011 Z ", encoding: 'ASCII-8BIT').strip)
          .to eq(described_class.new("\xC2\xA92011 Z", encoding: 'ASCII-8BIT'))
      end
    end
  end

  describe '#strip!' do
    context 'default behavior' do
      it 'removes leading/trailing spaces (in place)' do
        str = +' test  '
        expect(str.strip!).to be(str).and eq('test')
      end

      it 'removes trailing newlines (in place)' do
        str = +"test\n"
        expect(str.strip!).to be(str).and eq('test')
      end

      it 'does not remove internal spaces / newlines (in place)' do
        str = +"test \n test "
        expect(str.strip!).to be(str).and eq(str)
      end
    end

    context 'monkey-patched behavior' do
      it 'removes leading/trailing zero-width spaces, but not internal ones (in place)' do
        str = +" \r\n test \u{200B} \n test\u{200B} \u{200B}"
        expect(str.strip!).to be(str).and eq("test \u{200B} \n test")
      end

      it 'does not break on invalid-unicode strings (in place)' do
        str = described_class.new("\xC2\xA92011 Z ", encoding: 'ASCII-8BIT')
        expect(str.strip!)
          .to be(str).and eq(described_class.new("\xC2\xA92011 Z", encoding: 'ASCII-8BIT'))
      end
    end
  end

  describe '#to_filename' do
    it 'does not modify strings in place' do
      %w[test Some::File].each do |str|
        expect { str.to_filename }.not_to change { str }
      end
    end

    it 'leaves all-downcase strings as-is' do
      expect('test'.to_filename).to eq('test')
    end

    it 'converts camelcase Ruby constant paths to snakecase file paths' do
      expect('Some::File'.to_filename).to eq('some/file')
    end
  end

  describe '#to_classname' do
    it 'does not modify strings in place' do
      %w[test some/file].each do |str|
        expect { str.to_classname }.not_to change { str }
      end
    end

    it 'capitalizes all-downcase strings' do
      expect('test'.to_classname).to eq('Test')
    end

    it 'converts snakecase file paths to camelcase Ruby constant paths' do
      expect('some/file'.to_classname).to eq('Some::File')
    end

    context 'unlike ActiveSupport’s #classify' do
      it 'preserves pluralized names' do
        expect('some/files'.to_classname).to eq('Some::Files')
        expect('some_test/files'.to_classname).to eq('SomeTest::Files')
      end
    end
  end

  describe '#html2text' do
    it 'does not modify strings in place' do
      %w[test <div>test</div>].each do |str|
        expect { str.html2text }.not_to change { str }
      end
    end

    it 'leaves human-readable text as-is' do
      expect('test'.html2text).to eq('test')
    end

    it 'strips leading/trailing spaces' do
      expect('  test '.html2text).to eq('test')
    end

    it 'also strips leading/trailing newlines' do
      expect("\n\n  test \n\n\n".html2text).to eq('test')
    end

    it 'strips HTML tags around text content' do
      expect('<div>test</div>'.html2text).to eq('test')
    end

    it 'strips trailing <br> inside last <div>' do
      expect('<div>test<br></div>'.html2text).to eq('test')
    end

    it 'strips trailing <br> and newlines inside last <div>' do
      expect("<div>test<br><br><br>\n<br>\n<br>\n</div>".html2text).to eq('test')
    end

    it 'strips trailing <br>, newlines, and spaces inside last <div>' do
      expect("<div>test<br><br> <br> \n<br> \n<br> \n</div>".html2text).to eq('test')
    end

    it 'strips trailing <br>, newlines, and &nbsp; inside last <div>' do
      expect("<div>test<br><br>&nbsp;<br>&nbsp;\n<br>&nbsp;\n<br>&nbsp;\n</div>".html2text).to eq('test')
    end

    it 'strips trailing whitespace (including &nbsp; & <br>) both inside and after last tag' do
      expect("<div>test<br><br>&nbsp;<br>&nbsp;\n<br>&nbsp;\n<br>&nbsp;\n</div>&nbsp;".html2text).to eq('test')
    end

    it 'also strips nested HTML tags' do
      expect("<p><span>Was\nsoll verbessert werden:</span></p>".html2text)
        .to eq('Was soll verbessert werden:')
    end

    it 'in <pre> elements, collapses multiple newlines into one' do
      expect("<pre>test\n\ntest</pre>".html2text).to eq("test\ntest")
    end

    it 'in <code> elements, collapses multiple newlines into one' do
      expect("<code>test\n\ntest</code>".html2text).to eq("test\ntest")
    end

    it 'converts <table> cells and row to space-separated lines' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <table><tr><td>test</td><td>col</td></td></tr><tr><td>test</td><td>4711</td></tr></table>
      HTML
        test col
        test 4711
      TEXT
    end

    it 'strips HTML comments' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <!-- some comment -->
        <div>
        test<br><br><br>
        <br>
        <br>

        </div>
      HTML
        test
      TEXT
    end

    it 'converts <a> elements to plain text with numerical references' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)

        <div><a href="https://zammad.org">Best Tool of the World</a>
        some other text</div>
        <div>
      HTML
        [1] Best Tool of the Worldsome other text

        [1] https://zammad.org
      TEXT
    end

    it 'converts <hr> elements to separate paragraphs containing only "___"' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <!-- some comment -->
        <div>
        test<br><br><br>
        <hr/>
        <br>

        </div>
      HTML
        test

        ___
      TEXT
    end

    it 'converts <br> elements to newlines (max. 2)' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        test<br><br><br>--<br>abc</div>
      HTML
        test

        --
        abc
      TEXT
    end

    it 'strips Microsoft Outlook conditional comments' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        Ihr RZ-Team<br />
        <br />
        <!--[if gte mso 9]><xml> <o:DocumentProperties>  <o:Author>test</o:Author> =
         <o:Template>A75DB76E.dotm</o:Template>  <o:LastAuthor>test</o:LastAuthor> =
         <o:Revision>5</o:Revision>  <o:Created>2011-05-18T07:08:00Z</o:Created>  <=
        o:LastSaved>2011-07-04T17:59:00Z</o:LastSaved>  <o:Pages>1</o:Pages>  <o:Wo=
        rds>189</o:Words>  <o:Characters>1192</o:Characters>  <o:Lines>9</o:Lines> =
         <o:Paragraphs>2</o:Paragraphs>  <o:CharactersWithSpaces>1379</o:Characters=
        WithSpaces>  <o:Version>11.5606</o:Version> </o:DocumentProperties></xml><!=
        [endif]-->
      HTML
        Ihr RZ-Team
      TEXT
    end

    it 'strips <img> elements' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <html>
        <head>
        <title>Neues Fax von 1234-93900</title>
        </head>
        <body style="margin: 0px;padding: 0px;font-family: Arial, sans-serif;font-size: 12px;">
        <table cellpadding="0" cellspacing="0" width="100%" height="100%" bgcolor="#d9e7f0" id="mailbg"
        style="empty-cells:show;font-size: 12px;line-height: 18px;color: #000000;font-family: Arial, sans-serif;width: 100%;height: 100%;background-color: #d9e7f0;padding: 0px;margin: 0px;">
        <tr>
        <td valign="top">
        <center>
        <br><br>
        <table width="560" cellpadding="0" cellspacing="0" bgcolor="#FFFFFF" id="mailcontainer"
        style="empty-cells:show;font-size: 12px;line-height: 18px;color: #000000;font-family: Arial, sans-serif;width: 560px;margin: 0px auto;padding: 0px;background-color: #FFFFFF;">
        <tr>
        <td colspan="3" width="560" id="mail_header" valign="top" style="width: 560px;background-color: #FFFFFF;font-family: Arial, sans-serif;color: #000000;padding: 0px;margin: 0px;">
        <table width="560" cellpadding="0" cellspacing="0" style="empty-cells:show;font-size: 12px;line-height: 18px;color: #000000;font-family: Arial, sans-serif;">
        <tr>
        <td height="10" colspan="4" style="font-size:0px;line-height: 0px;padding:0px;height:10px;">
        <img src="http://www.example.docm/static/example.docm/mailtemplates/de_DE/team/img/tpl_header.gif" style="padding: 0px;margin: 0px;">
        </td>
        </tr>
        <tr>
        <td height="12" colspan="4"><span style="font-size:0px;line-height:0px;"> </span></td>
        </tr>
        <tr>
        <td height="27" width="30"> </td>
        <td height="27" width="397"><span class="mailtitle" style="font-family: Arial, sans-serif;color: #000000;font-size: 18px;line-height: 18px;font-weight: normal;">Neues Fax</span></td>
        <td height="27" width="103"><img src="http://www.example.docm/static/example.docm/mailtemplates/de_DE/team/img/tpl_logo-example.gif" style="padding: 0px;margin: 0px;"></td>
        <td height="27" width="30"></td>
        </tr>
        <tr>
        <td height="20" colspan="4"><span style="font-size:0px;line-height:0px;"> </span></td>
        </tr>
        <tr>
        <td height="1" colspan="4" style="font-size:0px;line-height: 0px;padding:0px;">
        <img src="http://www.example.docm/static/example.docm/mailtemplates/de_DE/team/img/tpl_line-grey.gif" style="padding: 0px;margin: 0px;">
        </td>
        </tr>
        </table>
        </td>
        </tr>
        <tr>
        <td colspan="3" width="560"> </td>
        </tr>
        <tr>
        <td width="30"> </td>
        <td width="500" height="30" valign="middle" align="right">
        <span class="accountno" style="font-family: Arial, sans-serif;font-size: 10px;color: #666666;">Ihre Kundennummer: 12345678</span>
        </td>
        <td width="30"> </td>
        </tr>
      HTML
        Neues Fax von 1234-93900

         Neues Fax

         Ihre Kundennummer: 12345678
      TEXT
    end

    it 'converts characters written in HTML ampersand code' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        line&nbsp;1<br>
        you<br/>
        -----&amp;
      HTML
        line\u00A01
        you
        -----&
      TEXT
    end

    it 'converts <ul> to asterisk-demarcated list' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        \u0020<ul><li>#1</li><li>#2</li></ul>
      HTML
        * #1
        * #2
      TEXT
    end

    it 'strips HTML frontmatter and <head> element' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <!DOCTYPE html>
        <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
          <head>
          <body style="font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;">
            <div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad.</div><div>&gt;</div>
          </body>
        </html>
      HTML
        > Welcome!
        >
        > Thank you for installing Zammad.
        >
      TEXT
    end

    it 'strips <style> elements' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        \u0020     <style type="text/css">
          body {
            width:90% !important;
            -webkit-text-size-adjust:90%;
            -ms-text-size-adjust:90%;
            font-family:\'helvetica neue\', helvetica, arial, geneva, sans-serif; f=
        ont-size: 12px;;
          }
          img {
            outline:none; text-decoration:none; -ms-interpolation-mode: bicubic;
          }
          a img {
            border:none;
          }
          table td {
            border-collapse: collapse;
          }
          table {
            border-collapse: collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;
          }
          p, table, div, td {
            max-width: 600px;
          }
          p {
            margin: 0;
          }
          blockquote, pre {
            margin: 0px;
            padding: 8px 12px 8px 12px;
          }

        </style><p>some other content</p>
      HTML
        some other content
      TEXT
    end

    it 'strips <meta> elements' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        \u0020       IT-Infrastruktur</span><br>
              <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
              <meta name="Generator" content="Microsoft Word 14 (filtered
                medium)">
              <!--[if !mso]><style>v\:* {behavior:url(#default#VML);}
        o\:* {behavior:url(#default#VML);}
        w\:* {behavior:url(#default#VML);}
        .shape {behavior:url(#default#VML);}
        </style><![endif]-->
              <style><!--

        @font-face
            {font-family:calibri;
            panose-1:2 15 5 2 2 2 4 3 2 4;}
        @font-face
            {font-family:tahoma;
            panose-1:2 11 6 4 3 5 4 4 2 4;}

        p.msonormal, li.msonormal, div.msonormal
            {margin:0cm;
            margin-bottom:.0001pt;
            font-size:11.0pt;
            font-family:"calibri","sans-serif";
            mso-fareast-language:en-us;}
        a:link, span.msohyperlink
            {mso-style-priority:99;
            color:blue;
            text-decoration:underline;}
        a:visited, span.msohyperlinkfollowed
            {mso-style-priority:99;
            color:purple;
            text-decoration:underline;}
        p.msoacetate, li.msoacetate, div.msoacetate
            {mso-style-priority:99;
            mso-style-link:"sprechblasentext zchn";
            margin:0cm;
            margin-bottom:.0001pt;
            font-size:8.0pt;
            font-family:"tahoma","sans-serif";
            mso-fareast-language:en-us;}
        span.e-mailformatvorlage17
            {mso-style-type:personal;
            font-family:"calibri","sans-serif";
            color:windowtext;}
        span.sprechblasentextzchn
            {mso-style-name:"sprechblasentext zchn";
            mso-style-priority:99;
            mso-style-link:sprechblasentext;
            font-family:"tahoma","sans-serif";}
        .msochpdefault
            {mso-style-type:export-only;
            font-family:"calibri","sans-serif";
            mso-fareast-language:en-us;}
        @page wordsection1
            {size:612.0pt 792.0pt;
            margin:70.85pt 70.85pt 2.0cm 70.85pt;}
        div.wordsection1
            {page:wordsection1;}
        --></style><!--[if gte mso 9]><xml>
        <o:shapedefaults v:ext="edit" spidmax="1026" />
        </xml><![endif]--><!--[if gte mso 9]><xml>
        <o:shapelayout v:ext="edit">
        <o:idmap v:ext="edit" data="1" />
        </o:shapelayout></xml><![endif]-->
      HTML
        IT-Infrastruktur
      TEXT
    end

    it 'separates block-level elements by one newline (<p> following a non-<p> block gets two)' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <h1>some head</h1>
        some content
        <blockquote>
        <p>line 1</p>
        <p>line 2</p>
        </blockquote>
        <p>some text later</p>
      HTML
        some head
        some content
        > line 1
        > line 2

        some text later
      TEXT
    end

    it 'formats <blockquote> contents with leading "> "' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <h1>some head</h1>
        some content
        <blockquote>
        line 1<br/>
        line 2<br>
        </blockquote>
        <p>some text later</p>
      HTML
        some head
        some content
        > line 1
        > line 2

        some text later
      TEXT
    end

    it 'adds max. 2 newlines between block-level <blockquote> contents' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <h1>some head</h1>
        some content
        <blockquote>
        <div><div>line 1</div><br></div>
        <div><div>line 2</div><br></div>
        </blockquote>
        some text later
      HTML
        some head
        some content
        > line 1
        >
        > line 2
        some text later
      TEXT
    end

    it 'places numerical <a> references at end of text string' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <p>Best regards,</p>
        <p><i>Your Team Team</i></p>
        <p>P.S.: You receive this e-mail because you are listed in our database as person who ordered a Team license. Please click
        <a href="http://www.teamviewer.example/en/company/unsubscribe.aspx?id=1009645&ident=xxx">here</a> to unsubscribe from further e-mails.</p>
        -----------------------------
        <br />
      HTML
        Best regards,
        Your Team Team
        P.S.: You receive this e-mail because you are listed in our database as person who ordered a Team license. Please click [1] here to unsubscribe from further e-mails.
        -----------------------------

        [1] http://www.teamviewer.example/en/company/unsubscribe.aspx?id=1009645&ident=xxx
      TEXT
    end

    it 'handles elements with missing closing tags' do
      expect(<<~HTML.chomp.html2text).to eq(<<~TEXT.chomp)
        <div><br>Dave and leaned her
        days adam.</div><span style="color:#F7F3FF; font-size:8px">Maybe we
        want any help me that.<br>Next morning charlie saw at their
        father.<br>Well as though adam took out here. Melvin will be more money.\u0020
        Called him into this one last thing.<br>Men-----------------------
        <br />
      HTML
        Dave and leaned her days adam.
        Maybe we want any help me that.
        Next morning charlie saw at their father.
        Well as though adam took out here. Melvin will be more money. Called him into this one last thing.
        Men-----------------------
      TEXT
    end

    context 'html encoding' do
      it 'converts &Auml; in Ä' do
        expect('<div>test something.&Auml;</div>'.html2text)
          .to eq('test something.Ä')
      end

      it 'strips invalid html encoding chars' do
        expect('<div>test something.&#55357;</div>'.html2text)
          .to eq('test something.í ˝')
      end
    end

    context 'performance tests' do
      let(:filler) do
        %(#{%(<p>some word <a href="http://example.com?domain?example.com">some url</a> and the end.</p>\n) * 11}\n)
      end

      it 'converts a 1076-byte unicode file in under 2s' do
        expect { Timeout.timeout(2) { <<~HTML.chomp.html2text } }.not_to raise_error
          <html>
          <title>some title</title>
          <body>

          <div>hello</div>

          #{filler}
          </body>
          </html>
        HTML
      end

      it 'converts a 2.21 MiB unicode file in under 2s' do
        expect { Timeout.timeout(2) { <<~HTML.chomp.html2text } }.not_to raise_error
          <html>
          <title>some title</title>
          <body>

          <div>hello</div>

          #{filler * 2312}
          </body>
          </html>
        HTML
      end

    end
  end

  describe '#html2html_strict' do
    it 'leaves human-readable text as-is' do
      expect('test'.html2html_strict).to eq('test')
    end

    it 'strips leading/trailing spaces' do
      expect('  test '.html2html_strict).to eq('test')
    end

    it 'also strips leading/trailing newlines' do
      expect("\n\n  test \n\n\n".html2html_strict).to eq('test')
    end

    it 'also strips leading <br>' do
      expect('<br><br><div>abc</div>'.html2html_strict).to eq('<div>abc</div>')
    end

    it 'also strips trailing <br> & spaces' do
      expect('<div>abc</div><br> <br>'.html2html_strict).to eq('<div>abc</div>')
    end

    it 'leaves <b> as-is' do
      expect('<b>test</b>'.html2html_strict).to eq('<b>test</b>')
    end

    it 'downcases tag names' do
      expect('<B>test</B>'.html2html_strict).to eq('<b>test</b>')
    end

    it 'leaves <i> as-is' do
      expect('<i>test</i>'.html2html_strict).to eq('<i>test</i>')
    end

    it 'leaves <h1> as-is' do
      expect('<h1>test</h1>'.html2html_strict).to eq('<h1>test</h1>')
    end

    it 'leaves <h2> as-is' do
      expect('<h2>test</h2>'.html2html_strict).to eq('<h2>test</h2>')
    end

    it 'leaves <h3> as-is' do
      expect('<h3>test</h3>'.html2html_strict).to eq('<h3>test</h3>')
    end

    it 'leaves <pre> as-is' do
      expect("<pre>a\nb\nc</pre>".html2html_strict).to eq("<pre>a\nb\nc</pre>")
    end

    it 'leaves <pre> nested inside <div> as-is' do
      expect("<div><pre>a\nb\nc</pre></div>".html2html_strict).to eq("<div><pre>a\nb\nc</pre></div>")
    end

    it 'strips HTML comments' do
      expect('<h3>test</h3><!-- some comment -->'.html2html_strict).to eq('<h3>test</h3>')
    end

    it 'strips <html>/<body> tags & <head> elements' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <html><head><base href="x-msg://2849/"></head><body style="word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space; "><span class="Apple-style-span" style="border-collapse: separate; font-family: Helvetica; font-style: normal; font-variant: normal; font-weight: normal; letter-spacing: normal; line-height: normal; orphans: 2; text-align: -webkit-auto; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-border-horizontal-spacing: 0px; -webkit-border-vertical-spacing: 0px; -webkit-text-decorations-in-effect: none; -webkit-text-size-adjust: auto; -webkit-text-stroke-width: 0px; font-size: medium; "><div lang="DE" link="blue" vlink="purple"><div class="Section1" style="page: Section1; "><div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; ">Hello Martin,<o:p></o:p></span></div>
      HTML
        <div lang="DE">Hello Martin,</div>
      TEXT
    end

    it 'strips <span> tags' do
      expect('<span></span>'.html2html_strict).to eq('')
    end

    it 'keeps style with color in <span>' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <span style="color: red; bgcolor: red">Hello Martin,</span>
      HTML
        <span style="color: red;">Hello Martin,</span>
      TEXT
    end

    it 'remove style=#ffffff with color in <span>' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <span style="color: #ffffff; bgcolor: red">Hello Martin,</span>
      HTML
        Hello Martin,
      TEXT
    end

    it 'strips <span> tags, id/class attrs, and <o:*> (MS Office) tags' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <div id="123" class="WordSection1">
        <p class="MsoNormal"><span style="color:#1F497D">Guten Morgen, Frau Koppenhagen,<o:p></o:p></span></p>
        <p class="MsoNormal"><span style="color:#1F497D"><o:p>&nbsp;</o:p></span></p>
        <p class="MsoNormal"><span style="color:#1F497D">vielen Dank für die Reservierung. Dabei allerdings die Sprache (Niederländisch) nicht erwähnt. Können Sie bitte dieses in Ihrer Reservierung vormerken?<o:p></o:p></span></p>
        <p class="MsoNormal"><span style="color:#1F497D"><o:p>&nbsp;</o:p></span></p>
        <p class="MsoNormal"><span style="color:#1F497D">Nochmals vielen Dank und herzliche Grüße
        <o:p></o:p></span></p>
        <div>
      HTML
        <div>
        <p><span style="color:#1f497d;">Guten Morgen, Frau Koppenhagen,</span></p><p><span style="color:#1f497d;"><p>&nbsp;</p></span></p><p><span style="color:#1f497d;">vielen Dank für die Reservierung. Dabei allerdings die Sprache (Niederländisch) nicht erwähnt. Können Sie bitte dieses in Ihrer Reservierung vormerken?</span></p><p><span style="color:#1f497d;"><p>&nbsp;</p></span></p><p><span style="color:#1f497d;">Nochmals vielen Dank und herzliche Grüße </span></p></div>
      TEXT
    end

    it 'strips <font> tags' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <p><font size="2"><a style="color: " href="http://www.example.com/?wm=mail"><img border="0" src="cid:example_new.png@8B201D8C.000B" width="101" height="30"></a></font></p>
      HTML
        <p><a href="http://www.example.com/?wm=mail" rel="nofollow noreferrer noopener" target="_blank" title="http://www.example.com/?wm=mail"><img border="0" src="cid:example_new.png@8B201D8C.000B" style="width:101px;height:30px;"></a></p>
      TEXT
    end

    it 'strips extraneous whitespace from end of opening tag' do
      expect('<b >test</b>'.html2html_strict).to eq('<b>test</b>')
    end

    it 'strips extraneous whitespace from closing tag' do
      expect('<b >test</b >'.html2html_strict).to eq('<b>test</b>')
    end

    it 'does not detect < /b > as closing tag; converts chars and auto-closes tag' do
      expect('<b >test< /b >'.html2html_strict).to eq('<b>test&lt; /b &gt;</b>')
    end

    it 'does not detect <\n/b> as closing tag; converts chars and auto-closes tag' do
      expect("<b\n>test<\n/b>".html2html_strict).to eq('<b>test&lt; /b&gt;</b>')
    end

    it 'collapses multiple whitespace-only <p> into one with &nbsp;' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <p> </p><p> </p><p> </p>
      HTML
        <p>&nbsp;</p>
      TEXT
    end

    it 'keeps lang attr on <p>' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <p lang="DE"><b><span></span></b></p>
      HTML
        <p lang="DE"></p>
      TEXT
    end

    it 'strips <span> inside <p>' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <p lang="DE"><b><span>Hello Martin,</span></b></p>
      HTML
        <p lang="DE"><b>Hello Martin,</b></p>
      TEXT
    end

    it 'strips empty <p> keep <p>s with content' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <p> </p><p>123</p><p></p>
      HTML
        <p>&nbsp;</p><p>123</p>
      TEXT
    end

    it 'strips <br> between <p>' do
      expect('<p>&nbsp;</p><br><br><p>&nbsp;</p>'.html2html_strict).to eq('<p>&nbsp;</p><p>&nbsp;</p>')
    end

    it 'auto-adds missing closing brackets on tags, but not opening brackets' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <b id=123 classs="
        some_class"
        >test<
        /b>
      HTML
        <b>test&lt; /b&gt;</b>
      TEXT
    end

    it 'auto-adds missing closing tags' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <ul id=123 classs="
        some_class"
        ><li>test</li>
        <li class="asasd">test</li><
        /ul>
      HTML
        <ul>
        <li>test</li>
        <li>test</li>&lt; /ul&gt;</ul>
      TEXT
    end

    it 'auto-closes <div> with missing closing tag; removes </p> with missing opening tag' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den <a href="http://newsletters.cylex.de/" class="">Link des Adventkalenders</a> in<br class="">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Ihrer Lesezeichen-Symbolleiste zu ergänzen.</p><div class="">&nbsp;
      HTML
        Damit Sie keinen Tag versäumen, empfehlen wir Ihnen den <a href="http://newsletters.cylex.de/" rel="nofollow noreferrer noopener" target="_blank" title="http://newsletters.cylex.de/">Link des Adventkalenders</a> in<br> Ihrer Lesezeichen-Symbolleiste zu ergänzen.<div> </div>
      TEXT
    end

    it 'intelligently inserts missing </td> & </tr> tags (and ignores misplaced </table> tags)' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <table>
        <tr>
        <td bgcolor=white><font size=2 face="sans-serif"><b>Franz Schäfer</b></font>
        <tr>
        <td bgcolor=white><font size=2 face="sans-serif">Manager Information Systems</font></table>
        <br>
        <table>
        <tr>
        <td bgcolor=white><font size=2 face="sans-serif">Telefon &nbsp;</font>
        <td bgcolor=white><font size=2 face="sans-serif">+49 000 000 8565</font>
        <tr>
        <td colspan=2 bgcolor=white><font size=2 face="sans-serif">christian.schaefer@example.com</font></table>
        <br>
        <table>
      HTML
        <table>
        <tr>
        <td>
        <b>Franz Schäfer</b>
        </td>
        </tr>
        <tr>
        <td>Manager Information Systems</td>
        </tr>
        </table>
        <br>
        <table>
        <tr>
        <td> Telefon </td>
        <td> +49 000 000 8565 </td>
        </tr>
        <tr>
        <td colspan="2">christian.schaefer@example.com</td>
        </tr>
        </table>
      TEXT
    end

    it 'ignores invalid (misspelled) attrs' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <b id=123 classs="
        some_class">test</b>
      HTML
        <b>test</b>
      TEXT
    end

    it 'strips incomplete CSS rules' do
      expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
        <p><a style="color: " href="http://www.example.com/?wm=mail"><img border="0" src="cid:example_new.png@8B201D8C.000B" width="101" height="30"></a></p>
      HTML
        <p><a href="http://www.example.com/?wm=mail" rel="nofollow noreferrer noopener" target="_blank" title="http://www.example.com/?wm=mail"><img border="0" src="cid:example_new.png@8B201D8C.000B" style="width:101px;height:30px;"></a></p>
      TEXT
    end

    context 'for whitespace-only <div>' do
      it 'preserves a single space' do
        expect('<div> </div>'.html2html_strict).to eq('<div> </div>')
      end

      it 'converts a lone <br> to &nbsp;' do
        expect('<div><br></div>'.html2html_strict).to eq('<div>&nbsp;</div>')
      end

      it 'converts three <br> to one &nbsp;' do
        expect('<div style="max-width: 600px;"><br><br><br></div>'.html2html_strict).to eq('<div>&nbsp;</div>')
      end

      it 'collapses two nested, whitespace-only <div> into a single &nbsp;' do
        expect('<div><div> </div><div> </div></div>'.html2html_strict).to eq('<div>&nbsp;</div>')
      end

      it 'collapses three nested, whitespace-only <div> into a single &nbsp;' do
        expect('<div><div> </div><div> </div><div> </div></div>'.html2html_strict).to eq('<div>&nbsp;</div>')
      end

      it 'collapses 2+ nested, whitespace-only <p> into \n<p>&nbsp;</p>' do
        expect('<div><p> </p><p> </p></div>'.html2html_strict).to eq("<div>\n<p>&nbsp;</p></div>")
      end
    end

    context 'for <div> with content' do
      it 'also strips trailing/leading newlines inside <div>' do
        expect("<div>\n\n\ntest\n\n\n</div>".html2html_strict).to eq('<div>test</div>')
      end

      it 'also strips trailing/leading newlines & tabs inside <div>' do
        expect("<div>\n\t\ntest\n\t\n</div>".html2html_strict).to eq('<div>test</div>')
      end

      it 'also strips trailing/leading newlines & tabs inside <div>, but not internal spaces' do
        expect("<div>\n\t\ntest  123\n\t\n</div>".html2html_strict).to eq('<div>test 123</div>')
      end

      it 'strips newlines from trailing whitespace; leaves up to two <br> (with spaces) as-is' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>
          <br> <p><b>Description</b></p>
          <br> <br> </div>
        HTML
          <div>
          <br> <p><b>Description</b></p><br> <br> </div>
        TEXT
      end

      it 'strips newlines from trailing whitespace; collapses 3+ <br> into two' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>
          <br> <p><b>Description</b></p>
          <br> <br> <br> </div>
        HTML
          <div>
          <br> <p><b>Description</b></p><br><br></div>
        TEXT
      end

      it 'removes unnecessary <div> nesting' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><div>Hello Martin,</div></div>
        HTML
          <div>Hello Martin,</div>
        TEXT
      end

      it 'keeps innermost <div> when removing nesting' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div lang="DE"><div><div>Hello Martin,</div></div></div>
        HTML
          <div lang="DE">Hello Martin,</div>
        TEXT
      end

      it 'keeps style with color in <div>' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div style="color: red; bgcolor: red">Hello Martin,</div>
        HTML
          <div style="color: red;">Hello Martin,</div>
        TEXT
      end

      it 'remove style=#ffffff with color in <div>' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div style="color: #ffffff; bgcolor: red">Hello Martin,</div>
        HTML
          <div>Hello Martin,</div>
        TEXT
      end

      it 'rearranges whitespace in nested <div>' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div lang="DE"><div><div>Hello Martin,</div> </div></div>
        HTML
          <div lang="DE">
          <div>Hello Martin,</div></div>
        TEXT
      end

      it 'adds newline where <br> starts or ends <div> content' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div style="max-width: 600px;"><br>abc<br><br></div>
        HTML
          <div>
          <br>abc<br><br>
          </div>
        TEXT
      end

      it 'leaves <s> nested in <div> as-is (?)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><s>abc</s></div>
        HTML
          <div><s>abc</s></div>
        TEXT
      end

      it 'collapses multiple whitespace-only <p> into one with &nbsp;' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><p> </p>
          <p> </p>
          <p> </p>
          </div>
        HTML
          <div>
          <p>&nbsp;</p></div>
        TEXT
      end

      it 'strips <div> tags when they contain only <p>' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>lala<div lang="DE"><p><span>Hello Martin,</span></p></div></div>
        HTML
          <div>lala<div lang="DE"><p>Hello Martin,</p></div></div>
        TEXT
      end
    end

    context 'link handling' do
      it 'adds rel & target attrs to <a> tags' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <a href="http://web.de">web.de</a>
        HTML
          <a href="http://web.de" rel="nofollow noreferrer noopener" target="_blank">web.de</a>
        TEXT
      end

      it 'removes id attrs' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <a id="123" href="http://web.de">web.de</a>
        HTML
          <a href="http://web.de" rel="nofollow noreferrer noopener" target="_blank">web.de</a>
        TEXT
      end

      it 'removes class/id attrs' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <a href="http://example.com" class="abc" id="123">http://example.com</a>
        HTML
          <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a>
        TEXT
      end

      it 'downcases <a> tags' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <A href="http://example.com?a=1;">http://example.com?a=1;</A>
        HTML
          <a href="http://example.com?a=1;" rel="nofollow noreferrer noopener" target="_blank">http://example.com?a=1;</a>
        TEXT
      end

      it 'doesn’t downcase href attr or inner text' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <A href="http://example.com/withSoMeUpper/And/downCase">http://example.com/withSoMeUpper/And/downCase</A>
        HTML
          <a href="http://example.com/withSoMeUpper/And/downCase" rel="nofollow noreferrer noopener" target="_blank">http://example.com/withSoMeUpper/And/downCase</a>
        TEXT
      end

      it 'automatically wraps <a> tags around valid URLs' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>https://www.facebook.com/test</div>
        HTML
          <div>\n<a href="https://www.facebook.com/test" rel="nofollow noreferrer noopener" target="_blank">https://www.facebook.com/test</a>\n</div>
        TEXT
      end

      it 'does not wrap URLs if leading https?:// is missing' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          some text www.example.com some other text
        HTML
          some text www.example.com some other text
        TEXT
      end

      it 'adds missing http:// to href attr (but not inner text)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          web <a href="www.example.com"><span style="color:blue">www.example.com</span></a>
        HTML
          web <a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank"><span style="color:blue;">www.example.com</span></a>
        TEXT
      end

      it 'includes URL parameters when wrapping URL in <a> tag' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <p>https://wiki.lab.example.com/doku.php?id=xxxx:start&a=1;#ldap</p>
        HTML
          <p><a href="https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;a=1;#ldap" rel="nofollow noreferrer noopener" target="_blank">https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;a=1;#ldap</a></p>
        TEXT
      end

      it 'does not rewrap valid URLs that already have <a> tags' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <a href="http://example.com">http://example.com</a>
        HTML
          <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a>
        TEXT
      end

      it 'recognizes URL parameters when matching href to inner text' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <p><a href="https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap">https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap</a></p>
        HTML
          <p><a href="https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap" rel="nofollow noreferrer noopener" target="_blank">https://wiki.lab.example.com/doku.php?id=xxxx:start&amp;#ldap</a></p>
        TEXT
      end

      it 'recognizes <br> as URL boundary' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><br>https://www.facebook.com/test<br></div>
        HTML
          <div>
          <br><a href="https://www.facebook.com/test" rel="nofollow noreferrer noopener" target="_blank">https://www.facebook.com/test</a><br>\n</div>
        TEXT
      end

      it 'recognizes space as URL boundary' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          some text http://example.com some other text
        HTML
          some text <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a> some other text
        TEXT
      end

      it 'wraps valid URLs from <div> elements in <a> tags' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>http://example.com</div>
        HTML
          <div>
          <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a>
          </div>
        TEXT
      end

      it 'recognizes trailing dot as URL boundary' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>http://example.com.</div>
        HTML
          <div>
          <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a>.</div>
        TEXT
      end

      it 'does not add a leading newline if <div> begins with non-URL text' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>lala http://example.com.</div>
        HTML
          <div>lala <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a>.</div>
        TEXT
      end

      it 'recognizes trailing comma as URL boundary' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>http://example.com, and so on</div>
        HTML
          <div>
          <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a>, and so on</div>
        TEXT
      end

      it 'recognizes trailing comma as URL boundary (immediately following URL parameters)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>http://example.com?lala=me, and so on</div>
        HTML
          <div>
          <a href="http://example.com?lala=me" rel="nofollow noreferrer noopener" target="_blank">http://example.com?lala=me</a>, and so on</div>
        TEXT
      end

      it 'strips <a> tags when no href is present' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <a name="_MailEndCompose"><span style="font-size:11.0pt;font-family:&quot;Calibri&quot;,&quot;sans-serif&quot;;color:#44546A">Hello Mr Smith,<o:p></o:p></span></a>
        HTML
          <span style="color:#44546a;">Hello Mr Smith,</span>
        TEXT
      end

      context 'when <a> inner text is HTML elements' do
        it 'leaves <img> elements as-is' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="http://example.com/?abc=123&123=abc" class="abc\n"\n><img src="cid:123"></a>
          HTML
            <a href="http://example.com/?abc=123&amp;123=abc" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com/?abc=123&amp;123=abc"><img src="cid:123"></a>
          TEXT
        end

        it 'strips <span> tags, but not content' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="http://facebook.de/examplesrbog"><span lang="EN-US" style='color:blue'>http://facebook.de/examplesrbog</span></a>
          HTML
            <a href="http://facebook.de/examplesrbog" rel="nofollow noreferrer noopener" target="_blank"><span lang="EN-US" style="color:blue;">http://facebook.de/examplesrbog</span></a>
          TEXT
        end

        it 'also strips surrounding <span> and <o:p> tags' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <span style="font-size:10.0pt;font-family:&quot;Cambria&quot;,serif;color:#1F497D;mso-fareast-language:DE">web&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
            <a href="http://www.example.com"><span style="color:blue">www.example.com</span></a><o:p></o:p></span>
          HTML
            <span style="color:#1f497d;">web <a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank"><span style="color:blue;">www.example.com</span></a></span>
          TEXT
        end
      end

      context 'when <a> inner text and href do not match' do
        it 'adds title attr' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="http://example.com">http://what-different.example.com</a>
          HTML
            <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com">http://what-different.example.com</a>
          TEXT
        end

        it 'converts unsafe characters in href attr and title' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="http://example.com %22test%22">http://what-different.example.com</a>
          HTML
            <a href="http://example.com%20%22test%22" rel="nofollow noreferrer noopener" target="_blank" title="http://example.com%20%22test%22">http://what-different.example.com</a>
          TEXT
        end

        it 'does not add title attr (for different capitalization)' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="http://example.com">http://EXAMPLE.com</a>
          HTML
            <a href="http://example.com" rel="nofollow noreferrer noopener" target="_blank">http://EXAMPLE.com</a>
          TEXT
        end

        it 'does not add title attr (for URL-safe/unsafe characters)' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="http://example.com/?abc=123&123=abc">http://example.com?abc=123&amp;123=abc</a>
          HTML
            <a href="http://example.com/?abc=123&amp;123=abc" rel="nofollow noreferrer noopener" target="_blank">http://example.com?abc=123&amp;123=abc</a>
          TEXT
        end
      end

      context 'for email links' do
        it 'strips <a> tags' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="mailto:john.smith@example.com" style="color: blue; text-decoration: underline; ">john.smith@example.com</a>
          HTML
            <a href="mailto:john.smith@example.com">john.smith@example.com</a>
          TEXT
        end

        it 'strips <a> tags (even with upcased "MAILTO:")' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="MAILTO:john.smith@example.com" style="color: blue; text-decoration: underline; ">john.smith@example.com</a>
          HTML
            <a href="MAILTO:john.smith@example.com">john.smith@example.com</a>
          TEXT
        end

        it 'extracts destination address when it differs from <a> innertext' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <a href="MAILTO:john.smith2@example.com" style="color: blue; text-decoration: underline; ">john.smith@example.com</a>
          HTML
            <a href="MAILTO:john.smith2@example.com">john.smith@example.com</a>
          TEXT
        end

      end
    end

    context 'for <img> tags' do
      it 'removes color CSS rule from style attr' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <img src="/some.png" style="color: blue; width: 30px; height: 50px">
        HTML
          <img src="/some.png" style=" width: 30px; height: 50px;">
        TEXT
      end

      it 'converts width/height attrs to CSS rules' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <img src="/some.png" width="30px" height="50px">
        HTML
          <img src="/some.png" style="width:30px;height:50px;">
        TEXT
      end

      it 'automatically adds terminal semicolons to CSS rules' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <img style="width: 181px; height: 125px" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">
        HTML
          <img style="width: 181px; height: 125px;" src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/...">
        TEXT
      end

      context 'when <img> nested in <a>, nested in <p>' do
        it 'sanitizes those elements as normal' do
          expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
            <p class="MsoNormal"><a href="http://www.example.com/"><span style="color:blue;text-decoration:none"><img border="0" width="30" height="30" id="_x0000_i1030" src="cid:image001.png@01D172FC.F323CDB0"></span></a><o:p></o:p></p>
          HTML
            <p><a href="http://www.example.com/" rel="nofollow noreferrer noopener" target="_blank" title="http://www.example.com/"><span style="color:blue;"><img border="0" src="cid:image001.png@01D172FC.F323CDB0" style="width:30px;height:30px;"></span></a></p>
          TEXT
        end
      end
    end

    context 'sample email input' do
      it 'handles sample input 1' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>
          abc<p><b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's </p></div>
        HTML
          <div>abc<span class=\"js-signatureMarker\"></span><p><b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's </p></div>
        TEXT
      end

      it 'handles sample input 2' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div> abc<p> <b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's </p></div>
        HTML
          <div>abc<span class=\"js-signatureMarker\"></span><p> <b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's </p></div>
        TEXT
      end

      it 'handles sample input 3' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div> abc<p> <b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's </p> </div>
        HTML
          <div>abc<span class=\"js-signatureMarker\"></span><p> <b>Von:</b> Fritz Bauer [mailto:me@example.com] <br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's </p></div>
        TEXT
      end

      it 'handles sample input 4' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; ">Mit freundlichem Gruß<span class="Apple-converted-space">&nbsp;</span><br><br>John Smith<br>Service und Support<br><br>Example Service AG &amp; Co.<o:p></o:p></span></div><div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; ">Management OHG<br>Someware-Str. 4<br>xxxxx Someware<br><br></span><span style="font-size: 10pt; font-family: Arial, sans-serif; "><o:p></o:p></span></div><div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; ">Tel.: +49 001 7601 462<br>Fax: +49 001 7601 472</span><span style="font-size: 10pt; font-family: Arial, sans-serif; "><o:p></o:p></span></div><div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; "><a href="mailto:john.smith@example.com" style=color: blue; text-decoration: underline; ">john.smith@example.com</a></span><span style="font-size: 10pt; font-family: Arial, sans-serif; "><o:p></o:p></span></div><div style="margin-top: 0cm; margin-right: 0cm; margin-left: 0cm; margin-bottom: 0.0001pt; font-size: 11pt; font-family: Calibri, sans-serif; "><span style="font-size: 10pt; font-family: Arial, sans-serif; "><a href="http://www.example.com" style="color: blue; text-decoration: underline; ">www.example.com</a></span><span style="font-size: 10pt; font-family: Arial, sans-serif; "><o:p></o:p></span></div>
        HTML
          <div><span>Mit freundlichem Gruß <br><br>John Smith<br>Service und Support<br><br>Example Service AG &amp; Co.</span></div><div>
          <span>Management OHG<br>Someware-Str. 4<br>xxxxx Someware<br><br></span>
          </div><div>
          <span>Tel.: +49 001 7601 462<br>Fax: +49 001 7601 472</span>
          </div><div>
          <a href="mailto:john.smith@example.com">john.smith@example.com</a>
          </div><div>
          <a href="http://www.example.com" rel="nofollow noreferrer noopener" target="_blank">www.example.com</a>
          </div>
        TEXT
      end

      it 'handles sample input 5' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <body lang="DE" link="blue" vlink="purple"><div class="WordSection1">
          <p class="MsoNormal"><span style="color:#1F497D">Guten Morgen, Frau ABC,<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="color:#1F497D"><o:p>&nbsp;</o:p></span></p>
          <p class="MsoNormal"><span style="color:#1F497D">vielen Dank für die Reservierung. Dabei allerdings die Sprache (Niederländisch) nicht erwähnt. Können Sie bitte dieses in Ihrer Reservierung vormerken?<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="color:#1F497D"><o:p>&nbsp;</o:p></span></p>
          <p class="MsoNormal"><span style="color:#1F497D">Nochmals vielen Dank und herzliche Grüße
          <o:p></o:p></span></p>
          <div>
          <p class="MsoNormal"><b><span style="font-size:10.0pt;color:#1F497D"><o:p>&nbsp;</o:p></span></b></p>
          <p class="MsoNormal"><b><span style="font-size:10.0pt;color:#1F497D">Anna Smith<o:p></o:p></span></b></p>
          <p class="MsoNormal"><b><span style="font-size:10.0pt;color:#1F497D">art abc SEV GmbH<o:p></o:p></span></b></p>
          <p class="MsoNormal"><b><span style="font-size:10.0pt;color:#1F497D">art abc TRAV<o:p></o:p></span></b></p>
          <p class="MsoNormal"><span style="font-size:9.0pt;color:#1F497D">Marktstätte 123<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="font-size:9.0pt;color:#1F497D">123456 Dorten<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="font-size:9.0pt;color:#1F497D">T: &#43;49 (0) 12345/1234560-1<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="font-size:9.0pt;color:#1F497D">T: &#43;49 (0) 12345/1234560-0<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="font-size:9.0pt;color:#1F497D">F: &#43;49 (0) 12345/1234560-2<o:p></o:p></span></p>
          <p class="MsoNormal"><a href="mailto:annad@example.com"><span style="font-size:9.0pt">annad@example.com</span></a><span style="font-size:9.0pt;color:#C00000"><o:p></o:p></span></p>
          <p class="MsoNormal"><a href="http://www.example.com/"><span style="font-size:9.0pt">www.example.com</span></a><span style="font-size:9.0pt;color:#1F497D">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
          </span><a href="http://www.ABC.com/"><span style="font-size:9.0pt">www.ABC.com</span></a><span style="font-size:9.0pt;color:#1F497D"><o:p></o:p></span></p>
          <p class="MsoNormal"><span style="font-size:8.0pt;color:#1F497D">Geschäftsführer Vor Nach, VorUndZu Nach&nbsp;&nbsp;&nbsp;&nbsp; -&nbsp;&nbsp;&nbsp;&nbsp; Amtsgericht Dort HRB 12345&nbsp;&nbsp;&nbsp; -&nbsp;&nbsp;&nbsp; Ein Unternehmer der ABC Gruppe<o:p></o:p></span></p>
        HTML
          <div>
          <p><span style="color:#1f497d;">Guten Morgen, Frau ABC,</span></p><p><span style="color:#1f497d;"><p>&nbsp;</p></span></p><p><span style="color:#1f497d;">vielen Dank für die Reservierung. Dabei allerdings die Sprache (Niederländisch) nicht erwähnt. Können Sie bitte dieses in Ihrer Reservierung vormerken?</span></p><p><span style="color:#1f497d;"><p>&nbsp;</p></span></p><p><span style="color:#1f497d;">Nochmals vielen Dank und herzliche Grüße </span></p><div>
          <p><b><span style="color:#1f497d;"><p>&nbsp;</p></span></b></p><p><b><span style="color:#1f497d;">Anna Smith</span></b></p><p><b><span style="color:#1f497d;">art abc SEV GmbH</span></b></p><p><b><span style="color:#1f497d;">art abc TRAV</span></b></p><p><span style="color:#1f497d;">Marktstätte 123</span></p><p><span style="color:#1f497d;">123456 Dorten</span></p><p><span style="color:#1f497d;">T: +49 (0) 12345/1234560-1</span></p><p><span style="color:#1f497d;">T: +49 (0) 12345/1234560-0</span></p><p><span style="color:#1f497d;">F: +49 (0) 12345/1234560-2</span></p><p><a href="mailto:annad@example.com">annad@example.com</a><span style="color:#c00000;"></span></p><p><a href="http://www.example.com/" rel="nofollow noreferrer noopener" target="_blank">www.example.com</a><span style="color:#1f497d;"> </span><a href="http://www.ABC.com/" rel="nofollow noreferrer noopener" target="_blank">www.ABC.com</a><span style="color:#1f497d;"></span></p><p><span style="color:#1f497d;">Geschäftsführer Vor Nach, VorUndZu Nach - Amtsgericht Dort HRB 12345 - Ein Unternehmer der ABC Gruppe</span></p></div></div>
        TEXT
      end

      it 'handles sample input 6' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <p class="MsoNormal"><span style="color:#1F497D"><o:p>&nbsp;</o:p></span></p>
          <div>
          <div style="border:none;border-top:solid #B5C4DF 1.0pt;padding:3.0pt 0cm 0cm 0cm">
          <p class="MsoNormal"><b><span style="font-size:10.0pt;font-family:&quot;Tahoma&quot;,&quot;sans-serif&quot;">Von:</span></b><span style="font-size:10.0pt;font-family:&quot;Tahoma&quot;,&quot;sans-serif&quot;"> Besucherbüro, MKuk [<a href="mailto:besucherbuero@example.com">mailto:besucherbuero@example.com</a>] <br>
          <b>Gesendet:</b> Freitag, 16. Dezember 2016 08:05<br>
          <b>An:</b> \'Amaia Epalza\'<br>
          <b>Betreff:</b> AW: Gruppe vtb Kultuur // 28.06.2017<o:p></o:p></span></p>
          </div>
          </div>
          <p class="MsoNormal"><o:p>&nbsp;</o:p></p>
          <p class="MsoNormal"><b><span style="font-size:10.0pt;font-family:&quot;Segoe UI&quot;,&quot;sans-serif&quot;;color:#1F497D">Reservierungsbestätigung Führung Skulptur-Projekte 2017 am
          </span></b><o:p></o:p></p>
          <p class="MsoNormal"><span style="font-size:10.0pt;font-family:&quot;Segoe UI&quot;,&quot;sans-serif&quot;;color:#1F497D">&nbsp;</span><o:p></o:p></p>
          <p class="MsoNormal">Guten Morgen Frau Epalza,<o:p></o:p></p>
        HTML
          <p><span style="color:#1f497d;"><p>&nbsp;</p></span></p><div>
          <div>
          <span class="js-signatureMarker"></span><p><b>Von:</b><span> Besucherbüro, MKuk [<a href="mailto:besucherbuero@example.com">mailto:besucherbuero@example.com</a>] <br>
          <b>Gesendet:</b> Freitag, 16. Dezember 2016 08:05<br>
          <b>An:</b> 'Amaia Epalza'<br>
          <b>Betreff:</b> AW: Gruppe vtb Kultuur // 28.06.2017</span></p></div></div><p>&nbsp;</p><p><b><span style="color:#1f497d;">Reservierungsbestätigung Führung Skulptur-Projekte 2017 am </span></b></p><p><span style="color:#1f497d;"> </span></p><p>Guten Morgen Frau Epalza,</p>
        TEXT
      end

      it 'handles sample input 7' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div class="">Wir brauchen also die Instanz <a href="http://example.zammad.com" class="">example.zammad.com</a>, kann die aber nicht mehr nutzen.</div><div class=""><br class=""></div><div class="">Bitte um Freischaltung.</div><div class=""><br class=""></div><div class=""><br class=""><div class="">
        HTML
          <div>Wir brauchen also die Instanz <a href="http://example.zammad.com" rel="nofollow noreferrer noopener" target="_blank">example.zammad.com</a>, kann die aber nicht mehr nutzen.</div><div>&nbsp;</div><div>Bitte um Freischaltung.</div><div>&nbsp;</div>
        TEXT
      end

      it 'handles sample input 8' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <p class="MsoNormal"><span style="font-size:11.0pt;font-family:&quot;Calibri&quot;,sans-serif;color:#1F497D;mso-fareast-language:EN-US">oh jeee … Zauberwort vergessen ;-) Können Sie mir
          <b>bitte</b> noch meine Testphase verlängern?<o:p></o:p></span></p>
          <p class="MsoNormal"><span style="font-size:11.0pt;font-family:&quot;Calibri&quot;,sans-serif;color:#1F497D;mso-fareast-language:EN-US"><o:p>&nbsp;</o:p></span></p>
        HTML
          <p><span style="color:#1f497d;">oh jeee … Zauberwort vergessen ;-) Können Sie mir <b>bitte</b> noch meine Testphase verlängern?</span></p><p><span style="color:#1f497d;"><p>&nbsp;</p></span></p>
        TEXT
      end

      it 'handles sample input 9' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><a href="http://www.example.com/Community/Passwort-Vergessen/?module_fnc=ChangeForgotPassword&amp;pwchangekey=66901c449dda98a098de4b57ccdf0805" title="http://www.example.com/Community/Passwort-Vergessen/?module_fnc%5BextranetHandler%5D=ChangeForgotPassword&amp;pwchangekey=66901c449dda98a098de4b57ccdf0805" rel="nofollow" target="_blank">http://www.example.com/Community/Passwort-Vergessen/?module_fnc%5BextranetHandler%5D=ChangeForgotPassword&amp;pwchangekey=66901c449dda98a098de4b57ccdf0805</a></div>
        HTML
          <div><a href="http://www.example.com/Community/Passwort-Vergessen/?module_fnc=ChangeForgotPassword&amp;pwchangekey=66901c449dda98a098de4b57ccdf0805" title="http://www.example.com/Community/Passwort-Vergessen/?module_fnc%5BextranetHandler%5D=ChangeForgotPassword&amp;pwchangekey=66901c449dda98a098de4b57ccdf0805" rel="nofollow noreferrer noopener" target="_blank">http://www.example.com/Community/Passwort-Vergessen/?module_fnc%5BextranetHandler%5D=ChangeForgotPassword&amp;pwchangekey=66901c449dda98a098de4b57ccdf0805</a></div>
        TEXT
      end

      it 'handles sample input 10' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <tr style="height: 15pt;" class=""><td width="170" nowrap="" valign="bottom" style="width: 127.5pt; border-style: none none none solid; border-left-width: 1pt; border-left-color: windowtext; padding: 0cm 5.4pt; height: 15pt;" class=""><p class="MsoNormal" align="center" style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;"><span style="" class="">&nbsp;</span></p></td><td width="58" nowrap="" valign="bottom" style="width: 43.5pt; padding: 0cm 5.4pt; height: 15pt;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="" class="">20-29</span></div></td><td width="47" nowrap="" valign="bottom" style="width: 35pt; background-color: rgb(255, 199, 206); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="color: rgb(156, 0, 6);" class="">200</span></div></td><td width="76" nowrap="" valign="bottom" style="width: 57pt; background-color: rgb(255, 199, 206); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="color: rgb(156, 0, 6);" class="">-1</span></div></td><td width="76" nowrap="" valign="bottom" style="width: 57pt; border-style: none solid none none; border-right-width: 1pt; border-right-color: windowtext; background-color: rgb(255, 199, 206); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="color: rgb(156, 0, 6);" class="">201</span></div></td><td width="107" nowrap="" valign="bottom" style="width: 80pt; padding: 0cm 5.4pt; height: 15pt;" class=""></td><td width="85" nowrap="" valign="bottom" style="width: 64pt; padding: 0cm 5.4pt; height: 15pt;" class=""></td><td width="101" nowrap="" valign="bottom" style="width: 76pt; border-style: none solid solid; border-left-width: 1pt; border-left-color: windowtext; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: gray; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><b class=""><span style="font-size: 10pt; font-family: Arial, sans-serif;" class="">country</span></b><span style="font-size: 11pt; font-family: Calibri, sans-serif;" class=""></span></div></td><td width="87" nowrap="" valign="bottom" style="width: 65pt; border-style: none solid solid none; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: gray; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="font-size: 10pt; font-family: Arial, sans-serif;" class="">Target (gross)</span></div></td><td width="123" nowrap="" valign="bottom" style="width: 92pt; border-style: none solid solid none; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: gray; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="font-size: 10pt; font-family: Arial, sans-serif;" class="">Remaining Recruits</span></div></td><td width="87" nowrap="" valign="bottom" style="width: 65pt; border-style: none solid solid none; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: windowtext; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt; height: 15pt; background-position: initial initial; background-repeat: initial initial;" class=""><div style="margin: 0cm 0cm 0.0001pt; font-size: 12pt; font-family: \'Times New Roman\', serif; text-align: center;" class=""><span style="font-size: 10pt; font-family: Arial, sans-serif;" class="">Total Recruits</span></div></td></tr>
        HTML
          <tr>
          <td valign="bottom" style=" border-style: none none none solid; border-left-width: 1pt; border-left-color: windowtext; padding: 0cm 5.4pt;"><p>&nbsp;</p></td>
          <td valign="bottom" style=" padding: 0cm 5.4pt;"><div>20-29</div></td>
          <td valign="bottom" style=" background-color: rgb(255, 199, 206); padding: 0cm 5.4pt;"><div><span style="color: rgb(156, 0, 6);">200</span></div></td>
          <td valign="bottom" style=" background-color: rgb(255, 199, 206); padding: 0cm 5.4pt;"><div><span style="color: rgb(156, 0, 6);">-1</span></div></td>
          <td valign="bottom" style=" border-style: none solid none none; border-right-width: 1pt; border-right-color: windowtext; background-color: rgb(255, 199, 206); padding: 0cm 5.4pt;"><div><span style="color: rgb(156, 0, 6);">201</span></div></td>
          <td valign="bottom" style=" padding: 0cm 5.4pt;"></td>
          <td valign="bottom" style=" padding: 0cm 5.4pt;"></td>
          <td valign="bottom" style=" border-style: none solid solid; border-left-width: 1pt; border-left-color: windowtext; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: gray; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt;"><div>
          <b>country</b>
          </div></td>
          <td valign="bottom" style=" border-style: none solid solid none; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: gray; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt;"><div>Target (gross)</div></td>
          <td valign="bottom" style=" border-style: none solid solid none; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: gray; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt;"><div>Remaining Recruits</div></td>
          <td valign="bottom" style=" border-style: none solid solid none; border-bottom-width: 1pt; border-bottom-color: gray; border-right-width: 1pt; border-right-color: windowtext; background-color: rgb(242, 242, 242); padding: 0cm 5.4pt;"><div>Total Recruits</div></td>
          </tr>
        TEXT
      end

      it 'handles sample input 11' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div style="line-height:1.7;color:#000000;font-size:14px;font-family:Arial"><div>Dear Bob<span style="line-height: 23.8px;">:</span><span style="color: rgb(255, 255, 255); line-height: 1.7;">Mr/Mrs</span></div><div><br></div><div><span style="line-height: 1.7;">We&nbsp;are&nbsp;one&nbsp;of&nbsp;the&nbsp;leading&nbsp;manufacturer&nbsp;and&nbsp;supplier&nbsp;of&nbsp;</span>conduits and cars since 3000.</div><div><br></div><div>Could you inform me the specification you need?</div><div><br></div><div>May I sent you our products catalogues for your reference?</div><div><br></div><div><img src="cid:5cb2783c$1$15ae9b384c8$Coremail$zhanabcdzhao$example.com" orgwidth="1101" orgheight="637" data-image="1" style="width: 722.7px; height: 418px; border: none;"></div><div>Best regards!</div><div><br></div><div><b style="line-height: 1.7;"><i><u><span lang="EL" style="font-size:11.0pt;font-family:&quot;Calibri&quot;,sans-serif;color:#17365D;\nmso-ansi-language:EL">Welcome to our booth B11/1 Hall 13 during SOMEWHERE\n9999.</span></u></i></b></div><div style="position:relative;zoom:1"><div>Bob Smith</div><div><div>Exp. &amp; Imp.</div><div>Town Example Electric Co., Ltd.</div><div>Tel: 0000-11-12345678 (Ext-220) &nbsp;Fax: 0000-11-12345678&nbsp;</div><div><span style="color:#17365d;">Room1234, NO. 638, Smith Road, Town, 200000, Somewhere</span></div><div>Web: www.example.com</div></div><div style="clear:both"></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div></div>
        HTML
          <div>\n<div>Dear Bob:<span style="color: rgb(255, 255, 255);">Mr/Mrs</span>
          </div><div>&nbsp;</div><div>We are one of the leading manufacturer and supplier of conduits and cars since 3000.</div><div>&nbsp;</div><div>Could you inform me the specification you need?</div><div>&nbsp;</div><div>May I sent you our products catalogues for your reference?</div><div>&nbsp;</div><div><img src="cid:5cb2783c%241%2415ae9b384c8%24Coremail%24zhanabcdzhao%24example.com" style="width: 722.7px; height: 418px;"></div><div>Best regards!</div><div>&nbsp;</div><div><b><i><u><span lang="EL" style="color:#17365d;">Welcome to our booth B11/1 Hall 13 during SOMEWHERE 9999.</span></u></i></b></div><div>\n<div>Bob Smith</div><div>\n<div>Exp. &amp; Imp.</div><div>Town Example Electric Co., Ltd.</div><div>Tel: 0000-11-12345678 (Ext-220) Fax: 0000-11-12345678</div><div><span style="color:#17365d;">Room1234, NO. 638, Smith Road, Town, 200000, Somewhere</span></div><div>Web: www.example.com</div></div></div></div>
        TEXT
      end

      it 'handles sample input 12' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <li><a style="font-size:15px; font-family:Arial;color:#0f7246" class="text_link" href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh"><span style="color: rgb(0, 0, 0);">Luxemburg</span></a></li>
        HTML
          <li><a href="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh" rel="nofollow noreferrer noopener" target="_blank" title="http://business-catalogs.example.com/ODtpbGs5MWIzbjUyYzExLTA4Yy06Mmg7N3AvL3R0bmFvY3B0LXlhbW9sc2Nhb3NnYy5lL3RpbXJlZi9lbS9ycnJuaWFpZXMsdGxnY25pLGUsdXJ0b3NVTGVpNWZ8fGZh">Luxemburg</a></li>
        TEXT
      end
    end

    context 'signature recognition' do
      let(:marker) { '<span class="js-signatureMarker"></span>' }

      it 'places marker before "--" line (surrounded by <br>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          lalala<br>--<br>Max Mix
        HTML
          lalala#{marker}<br>--<br>Max Mix
        TEXT
      end

      it 'places marker before "--" line (surrounded by <br/>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          lalala<br/>--<br/>Max Mix
        HTML
          lalala#{marker}<br>--<br>Max Mix
        TEXT
      end

      it 'places marker before "--" line (preceded by <br/>\n)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          lalala<br/>
          --<br/>Max Mix
        HTML
          lalala#{marker}<br> --<br>Max Mix
        TEXT
      end

      it 'places marker before "--" line (surrounded by <p>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          lalala<p>--</p>Max Mix
        HTML
          lalala#{marker}<p>--</p>Max Mix
        TEXT
      end

      it 'places marker before "__" line (surrounded by <br>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          lalala<br>__<br>Max Mix
        HTML
          lalala#{marker}<br>__<br>Max Mix
        TEXT
      end

      it 'places marker before quoted reply’s "Von:" header (in German)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          den.<br><br><b>Von:</b> Fritz Bauer [mailto:me@example.com]<br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's<br><br>Hello,<br><br>ich versuche an den Punkten
        HTML
          den.<br>#{marker}<br><b>Von:</b> Fritz Bauer [mailto:me@example.com]<br><b>Gesendet:</b> Donnerstag, 3. Mai 2012 11:51<br><b>An:</b> John Smith<br><b>Cc:</b> Smith, John Marian; johnel.fratczak@example.com; ole.brei@example.com; Günther John | Example GmbH; bkopon@example.com; john.heisterhagen@team.example.com; sven.rocked@example.com; michael.house@example.com; tgutzeit@example.com<br><b>Betreff:</b> Re: OTRS::XXX Erweiterung - Anhänge an CI's<br><br>Hello,<br><br>ich versuche an den Punkten
        TEXT
      end

      it 'places marker before quoted reply’s "Von:" header (as <p> with stripped parent <div>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><div style="border:none;border-top:solid #e1e1e1 1.0pt;padding:3.0pt 0cm 0cm 0cm"><p class="MsoNormal"><b><span lang="DE" style="font-size:11.0pt;font-family:&quot;Calibri&quot;,sans-serif">Von:</span></b><span lang="DE" style="font-size:11.0pt;font-family:&quot;Calibri&quot;,sans-serif"> Martin Edenhofer via Zammad Helpdesk [mailto:<a href="mailto:support@example.com">support@zammad.com</a>] <br><b>Gesendet:</b>\u0020
        HTML
          <div>#{marker}<p><b><span lang="DE">Von:</span></b><span lang="DE"> Martin Edenhofer via Zammad Helpdesk [mailto:<a href="mailto:support@example.com">support@zammad.com</a>] <br><b>Gesendet:</b> </span></p></div>
        TEXT
      end

      it 'places marker before quoted reply’s "Von:" header (as <p> with  parent <div>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div style="border:none;border-top:solid #B5C4DF 1.0pt;padding:3.0pt 0cm 0cm 0cm">
          <p class="MsoNormal" style="margin-left:35.4pt"><b><span style="font-family:Calibri;color:black">Von:
          </span></b><span style="font-family:Calibri;color:black">Johanna Kiefer via Znuny Projects &lt;projects@example.com&gt;<br>
          <b>Organisation: </b>Znuny Group<br>
          <b>Datum: </b>Montag, 6. März 2017 um 13:32<br>
        HTML
          <div>
          #{marker}<p><b>Von: </b><span>Johanna Kiefer via Znuny Projects &lt;projects@example.com&gt;<br>
          <b>Organisation: </b>Znuny Group<br>
          <b>Datum: </b>Montag, 6. März 2017 um 13:32<br></span></p></div>
        TEXT
      end

      it 'places marker before quoted reply’s "Von:" header (as <div>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div><br>
          <br>
          <br><font size=1 color=#5f5f5f face="sans-serif">Von: &nbsp; &nbsp; &nbsp;
          &nbsp;</font><font size=1 face="sans-serif">Hotel &lt;info@example.com&gt;</font>
          <br><font size=1 color=#5f5f5f face="sans-serif">An: &nbsp; &nbsp; &nbsp;
          &nbsp;</font></div>
        HTML
          #{marker}<div><br>Von: Hotel &lt;info@example.com&gt; <br>An: </div>
        TEXT
      end

      it 'places marker before English quoted text intro (as <blockquote>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <br class=""><div><blockquote type="cite" class=""><div class="">On 04 Mar 2017, at 14:47, Oliver Ruhm &lt;<a href="mailto:oliver@example.com" class="">oliver@example.com</a>&gt; wrote:</div><br class="Apple-interchange-newline">
        HTML
          <div>#{marker}<blockquote type="cite">
          <div>On 04 Mar 2017, at 14:47, Oliver Ruhm &lt;<a href="mailto:oliver@example.com">oliver@example.com</a>&gt; wrote:</div><br>
          </blockquote></div>
        TEXT
      end

      it 'does not place marker if blockquote doesn’t contain a quoted text intro' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <br class=""><div><blockquote type="cite" class=""><div class="">some note</div><br class="Apple-interchange-newline">
        HTML
          <div><blockquote type="cite">
          <div>some note</div><br>
          </blockquote></div>
        TEXT
      end

      it 'does not place marker if quoted text intro isn’t followed by a <blockquote>' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>
          <br> Am 17.03.2017 um 17:03 schrieb Martin Edenhofer via Zammad Helpdesk &lt;support@example.com&gt;:<br>
          <br>
          </div>
        HTML
          <div>
          <br> Am 17.03.2017 um 17:03 schrieb Martin Edenhofer via Zammad Helpdesk &lt;support@example.com&gt;:<br>
          <br>
          </div>
        TEXT
      end

      it 'places marker before German quoted text intro (before <blockquote>)' do
        expect(<<~HTML.chomp.html2html_strict).to eq(<<~TEXT.chomp)
          <div>
          <br> Am 17.03.2017 um 17:03 schrieb Martin Edenhofer via Zammad Helpdesk &lt;support@example.com&gt;:<br>
          <br>
          </div>

          <blockquote type="cite">
          <div>Dear Mr. Smith,<br></div>
          </blockquote>
        HTML
          #{marker}<div>
          <br> Am 17.03.2017 um 17:03 schrieb Martin Edenhofer via Zammad Helpdesk &lt;support@example.com&gt;:<br>
          <br>
          </div><blockquote type="cite">
          <div>Dear Mr. Smith,<br>
          </div></blockquote>
        TEXT
      end
    end
  end

  describe '#signature_identify' do
    let(:marker) { '######SIGNATURE_MARKER######' }

    context 'with no signature present' do
      it 'leaves string as-is' do
        expect((+'foo').signature_identify('text', true)).to eq('foo')
      end
    end

    context 'with signature present' do
      it 'places marker at start of "--" line' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          foo
          --
          bar
        SRC
          foo
          #{marker}--
          bar
        MARKED
      end

      it 'places marker before English quoted text intro' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          On 01/04/15 10:55, Bob Smith wrote:
        SRC
          #{marker}On 01/04/15 10:55, Bob Smith wrote:
        MARKED
      end

      it 'places marker before German quoted text intro' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          Am 03.04.2015 um 20:58 schrieb Martin Edenhofer <me@znuny.ink>:
        SRC
          #{marker}Am 03.04.2015 um 20:58 schrieb Martin Edenhofer <me@znuny.ink>:
        MARKED
      end

      it 'ignores trailing empty line' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          test 123
          test 123
          --
          Bob Smith

        SRC
          test 123
          test 123
          #{marker}--
          Bob Smith

        MARKED
      end

      it 'ignores trailing double empty lines' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          test 123
          test 123
          --
          Bob Smith


        SRC
          test 123
          test 123
          #{marker}--
          Bob Smith


        MARKED
      end

      it 'ignores leading/trailing empty lines' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)

          test 123\u0020
          1
          2
          3
          4
          5
          6
          7
          8
          9
          --
          Bob Smith

        SRC

          test 123\u0020
          1
          2
          3
          4
          5
          6
          7
          8
          9
          #{marker}--
          Bob Smith

        MARKED
      end

      it 'ignores lines starting with "--" but containing more text' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          test 123\u0020
          --no not match--
          --
          Bob Smith

        SRC
          test 123\u0020
          --no not match--
          #{marker}--
          Bob Smith

        MARKED
      end

      it 'places marker at start of " -- " line' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          test 123\u0020
          --no not match--
           --\u0020
          Bob Smith

        SRC
          test 123\u0020
          --no not match--
          #{marker} --\u0020
          Bob Smith

        MARKED
      end

      it 'places marker on empty line if possible / only places one marker' do
        expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
          test 123\u0020

          --
          Bob Smith




          --
          Bob Smith

        SRC
          test 123\u0020
          #{marker}
          --
          Bob Smith




          --
          Bob Smith

        MARKED
      end

      context 'for Apple email quote text' do
        context 'in English' do
          it 'places two markers, one before quoted text intro and one at start of "--" line' do
            expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
              test 123\u0020
              --no not match--
              Bob Smith
              On 01/04/15 10:55, Bob Smith wrote:
              lalala
              --
              some test
            SRC
              test 123\u0020
              --no not match--
              Bob Smith
              #{marker}On 01/04/15 10:55, Bob Smith wrote:
              lalala
              #{marker}--
              some test
            MARKED
          end
        end

        context 'auf Deutsch' do
          it 'places marker before quoted text intro' do
            expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
              test 123\u0020

              --no not match--

              Bob Smith
              Am 03.04.2015 um 20:58 schrieb Bob Smith <bob@example.com>:
              lalala
            SRC
              test 123\u0020

              --no not match--

              Bob Smith
              #{marker}Am 03.04.2015 um 20:58 schrieb Bob Smith <bob@example.com>:
              lalala
            MARKED
          end
        end
      end

      context 'for MS email quote text' do
        context 'in English' do
          it 'places marker before quoted text intro' do
            expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
              test 123test 123\u0020

              --no not match--

              Bob Smith
              From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
              Sent: Donnerstag, 2. April 2015 10:00
              lalala</div>
            SRC
              test 123test 123\u0020

              --no not match--

              Bob Smith
              #{marker}From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
              Sent: Donnerstag, 2. April 2015 10:00
              lalala</div>
            MARKED
          end
        end

        context 'auf Deutsch' do
          it 'places marker before quoted text intro' do
            expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)
              test 123\u0020

              --no not match--

              Bob Smith
              Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
              Gesendet: Donnerstag, 2. April 2015 10:00
              Betreff: lalala

            SRC
              test 123\u0020

              --no not match--

              Bob Smith
              #{marker}Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
              Gesendet: Donnerstag, 2. April 2015 10:00
              Betreff: lalala

            MARKED
          end
        end

        context 'en francais' do
          it 'places marker before quoted text intro' do
            expect(<<~SRC.chomp.signature_identify('text', true)).to eq(<<~MARKED.chomp)

              test 123\u0020

              --no not match--

              Bob Smith
              De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
              Envoyé : mercredi 29 avril 2015 17:31
              Objet : lalala

            SRC

              test 123\u0020

              --no not match--

              Bob Smith
              #{marker}De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
              Envoyé : mercredi 29 avril 2015 17:31
              Objet : lalala

            MARKED
          end
        end
      end
    end
  end

  describe '#utf8_encode' do
    context 'on valid, UTF-8-encoded strings' do
      let(:subject) { 'hello' }

      it 'returns an identical copy' do
        expect(subject.utf8_encode).to eq(subject)
        expect(subject.utf8_encode.encoding).to be(subject.encoding)
        expect(subject.utf8_encode).not_to be(subject)
      end

      context 'which are incorrectly set to other, technically valid encodings' do
        let(:subject) { described_class.new('ö', encoding: 'tis-620') }

        it 'sets input encoding to UTF-8 instead of attempting conversion' do
          expect(subject.utf8_encode).to eq(subject.dup.force_encoding('utf-8'))
        end
      end
    end

    context 'on strings in other encodings' do
      let(:subject) { original_string.encode(input_encoding) }

      context 'with no from: option' do
        let(:original_string) { 'Tschüss!' }
        let(:input_encoding) { Encoding::ISO_8859_2 }

        it 'detects the input encoding' do
          expect(subject.utf8_encode).to eq(original_string)
        end
      end

      context 'with a valid from: option' do
        let(:original_string) { 'Tschüss!' }
        let(:input_encoding) { Encoding::ISO_8859_2 }

        it 'uses the specified input encoding' do
          expect(subject.utf8_encode(from: 'iso-8859-2')).to eq(original_string)
        end

        it 'uses any valid input encoding, even if not correct' do
          expect(subject.utf8_encode(from: 'gb18030')).to eq('Tsch黶s!')
        end
      end

      context 'with an invalid from: option' do
        let(:original_string) { '―陈志' }
        let(:input_encoding) { Encoding::GB18030 }

        it 'does not try it' do
          expect { subject.encode('utf-8', 'gb2312') }
            .to raise_error(Encoding::InvalidByteSequenceError)

          expect { subject.utf8_encode(from: 'gb2312') }
            .not_to raise_error
        end

        it 'uses the detected input encoding instead' do
          expect(subject.utf8_encode(from: 'gb2312')).to eq(original_string)
        end
      end
    end

    context 'performance' do
      let(:subject) { original_string.encode(input_encoding) }

      context 'with utf8_encode in iso-8859-1' do
        let(:original_string) { 'äöü0' * 999_999 }
        let(:input_encoding) { Encoding::ISO_8859_1 }

        it 'detects the input encoding' do
          Timeout.timeout(1) do
            expect(subject.utf8_encode(from: 'iso-8859-1')).to eq(original_string)
          end
        end
      end

      context 'with utf8_encode in utf-8' do
        let(:original_string) { 'äöü0' * 999_999 }
        let(:input_encoding) { Encoding::UTF_8 }

        it 'detects the input encoding' do
          Timeout.timeout(1) do
            expect(subject.utf8_encode(from: 'utf-8')).to eq(original_string)
          end
        end
      end

      context 'with utf8_encode in iso-8859-1 and charset detection' do
        let(:original_string) { 'äöü0' * 199_999 }
        let(:input_encoding) { Encoding::ISO_8859_1 }

        it 'detects the input encoding' do
          Timeout.timeout(18) do
            expect(subject.utf8_encode(from: 'utf-8')).to eq(original_string)
          end
        end
      end
    end
  end
end
