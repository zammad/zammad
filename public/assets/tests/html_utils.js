window.onload = function() {

// textCleanup
test("textCleanup", function() {

  var source = "Some\nValue\n\n\nTest"
  var should = "Some\nValue\n\nTest"
  var result = App.Utils.textCleanup(source)
  equal(result, should, source)

  source = "Some\nValue\n\n \n\n\nTest"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup(source)
  equal(result, should, source)

  source = "Some\n\rValue\n\r\n\r\n\rTest"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup(source)
  equal(result, should, source)

  source = "Some\n\rValue\n\r\n\r\n\rTest\r"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup(source)
  equal(result, should, source)

  source = "Some\r\nValue\r\n\r\n\r\nTest\r\n"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup(source)
  equal(result, should, source)

  source = "Some\r\nValue\r\n\r\n\r\n\r\n\r\n\r\nTest\r\n"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup(source)
  equal(result, should, source)

  source = "> Welcome!\n> \n> Thank you for installing Zammad.\n> \n> You will find ..."
  should = "> Welcome!\n>\n> Thank you for installing Zammad.\n>\n> You will find ..."
  result = App.Utils.textCleanup(source)
  equal(result, should, source)


});

// text2html
test("text2html", function() {

  var source = "Some\nValue\n\n\nTest"
  var should = "<div>Some</div><div>Value</div><div><br></div><div>Test</div>"
  var result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some\nValue\n"
  should = "<div>Some</div><div>Value</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some\n<b>Value</b>\n"
  should = "<div>Some</div><div>&lt;b&gt;Value&lt;/b&gt;</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "> Welcome!\n> \n> Thank you for installing Zammad.\n> \n> You will find ..."
  should = "<div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad.</div><div>&gt;</div><div>&gt; You will find ...</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

});

// html2text
test("html2text", function() {

  var source = "<div>Some</div><div>Value</div><div><br></div><div>Test</div>"
  var should = "Some\nValue\n\nTest"
  var result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>Some</div><div>Value</div>"
  should = "Some\nValue"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>Some<br/>Value</div>"
  should = "Some\nValue"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>Some</div><div>&lt;b&gt;Value&lt;/b&gt;</div>"
  should = "Some\n<b>Value</b>"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad.</div><div>&gt;</div><div>&gt; You will find ...</div>"
  should = "> Welcome!\n>\n> Thank you for installing Zammad.\n>\n> You will find ..."
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>test 123 <br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>--<br/>Bob Smith</div>"
  should = "test 123 \n\n--\nBob Smith"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "test 123 <br><br><br><br><br><br><br><br><br><br><br>--<br>Bob Smith"
  should = "test 123 \n\n--\nBob Smith"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>1<br><br><br><br><br><br><br><br><br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div>"
  should = "1\n\nVon: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]\nGesendet: Donnerstag, 2. April 2015 11:32"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<div>test 123<br/>lalala<p>--</p>some test</div>"
  should = "test 123\nlalala\n--\nsome test"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  source = "<p><span>Was\nsoll verbessert werden:</span></p>"
  should = "Was soll verbessert werden:"
  result = App.Utils.html2text(source)
  equal(result, should, source)

  // in raw format, without cleanup
  source = "<div>Some</div><div>1234</div>"
  should = "Some\n1234\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

  source = "<div>Some</div><div> 1234</div>"
  should = "Some\n 1234\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

  source = "\n\n<div>Some</div>\n<div> 1234</div>"
  should = "Some\n 1234\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

  source = "<div>Some</div><div>  1234</div>"
  should = "Some\n  1234\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

  source = "<div>Some</div>\n\n<div>  1234</div>\n"
  should = "Some\n  1234\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

  source = "<div>test<br>new line<br></div>"
  should = "test\nnew line\n\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

  source = "<p><span>Was\nsoll verbessert werden:</span></p>"
  should = "Was soll verbessert werden:\n"
  result = App.Utils.html2text(source, true)
  equal(result, should, source)

});

// linkify
test("linkify", function() {

  var source = "http://example.com"
  var should = '<a href="http://example.com" title="http://example.com" target="_blank">http://example.com</a>'
  var result = App.Utils.linkify(source)
  equal(result, should, source)

  source = "http://example.com?some_param=lalala"
  should = '<a href="http://example.com?some_param=lalala" title="http://example.com?some_param=lalala" target="_blank">http://example.com?some_param=lalala</a>'
  result = App.Utils.linkify(source)
  equal(result, should, source)

  source = "example.com"
  should = '<a href="http://example.com" title="http://example.com" target="_blank">example.com</a>'
  result = App.Utils.linkify(source)
  equal(result, should, source)

  source = "some text example.com"
  should = 'some text <a href="http://example.com" title="http://example.com" target="_blank">example.com</a>'
  result = App.Utils.linkify(source)
  equal(result, should, source)

  source = "example.com some text"
  should = '<a href="http://example.com" title="http://example.com" target="_blank">example.com</a> some text'
  result = App.Utils.linkify(source)
  equal(result, should, source)

  /*
  source = "<b>example.com</b>"
  should = '<b><a href="http://example.com" title="http://example.com" target="_blank">http://example.com</a></b>'
  result = App.Utils.linkify(source)
  equal(result, should, source)
  */

});

// htmlEscape
test("htmlEscape", function() {

  var source = "<"
  var should = "&lt;"
  var result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = ">"
  should = "&gt;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "&"
  should = "&amp;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "&amp;"
  should = "&amp;amp;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "&amp ;"
  should = "&amp;amp ;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "& amp;"
  should = "&amp; amp;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "'test'"
  should = "&#39;test&#39;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = '"test"'
  should = "&quot;test&quot;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "<>"
  should = "&lt;&gt;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

  source = "<&lt;>"
  should = "&lt;&amp;lt;&gt;"
  result = App.Utils.htmlEscape(source)
  equal(result, should, source)

});

// htmlRemoveTags
test("htmlRemoveTags", function() {

  var source = "<div>test</div>"
  //var should = "<div>test</div>"
  var should = "test"
  var result = App.Utils.htmlRemoveTags($(source))
  equal(result.html(), should, source)

  source = "<div>test<!-- some comment --></div>"
  //should = "<div>test</div>"
  should = "test"
  result = App.Utils.htmlRemoveTags($(source))
  equal(result.html(), should, source)

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveTags($(source))
  equal(result.html(), should, source)

  source = "<div><a href=\"some_link\">some link to somewhere</a></div>"
  //should = "<div>some link to somewhere</div>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveTags($(source))
  equal(result.html(), should, source)

  source = "<div><a href=\"some_link\">some link to somewhere</a><input value=\"should not be shown\"></div>"
  //should = "<div>some link to somewhere</div>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveTags($(source))
  equal(result.html(), should, source)

  source = "<div><a href=\"some_link\">some link to somewhere</a> <div><hr></div> <span>123</span> <img src=\"some_image\"/></div>"
  //should = "<div>some link to somewhere  123 </div>"
  should = "some link to somewhere  123 "
  result = App.Utils.htmlRemoveTags($(source))
  equal(result.html(), should, source)

  source = "<div><form class=\"xxx\">test 123</form><svg><use xlink:href=\"assets/images/icons.svg#icon-status\"></svg></div>"
  //should = "<div>test 123</div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><textarea class=\"xxx\">test 123</textarea></div>"
  //should = "<div>test 123</div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)
  result = App.Utils.htmlRemoveRichtext(source)
  equal(result.html(), should, source)

});

// htmlRemoveRichtext
test("htmlRemoveRichtext", function() {

  var source = "<div><!--test comment--><a href=\"test\">test</a></div>"
  //var should = "<div>test</div>"
  var should = "test"
  var result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><!--[if !supportLists]--><span lang=\"DE\">1.1.1<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></span><!--[endif]--><span lang=\"DE\">Description</span></div>"
  //should = "<div><span>1.1.1<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></span><span>Description</span></div>"
  should = "<span>1.1.1<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></span><span>Description</span>"
  //should = '1.1.1     Description'
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><a href=\"some_link\"></a> test </div>"
  //should = "<div> test </div>"
  should = " test "
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><b></b> test </div>"
  //should = "<div> test </div>"
  should = " test "
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><div><b></b> test </div></div>"
  //should = "<div><div> test </div></div>"
  should = "<div> test </div>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><div><b></b> test <input value=\"should not be shown\"></div></div>"
  //should = "<div><div> test </div></div>"
  should = "<div> test </div>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><div><b></b> test </div><span>123</span></div>"
  //should = "<div><div> test </div><span>123</span></div>"
  should = "<div> test </div><span>123</span>"
  //should = '<div> test </div>123'
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><div class=\"xxx\" title=\"some title\" lang=\"en\"><b></b> test </div></div>"
  //should = "<div><div> test </div></div>"
  should = "<div> test </div>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><textarea class=\"xxx\"> test </textarea></div>"
  //should = "<div> test </div>"
  should = " test "
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><br></div>"
  //should = "<div><br></div>"
  should = "<br>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><div class=\"xxx\"><br></div></div>"
  //should = "<div><div><br></div></div>"
  should = "<div><br></div>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><form class=\"xxx\">test 123</form></div>"
  //should = "<div>test 123</div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><div><label for=\"Ticket_888344_group_id\">Gruppe <span>*</span></label></div><div><div></div></div><div><div><span></span><span></span></div></div><div><div><label for=\"Ticket_888344_owner_id\">Besitzer <span></span></label></div><div><div></div></div></div><div><div><div><svg><use xlink:href=\"http://localhost:3000/assets/images/icons.svg#icon-arrow-down\"></use></svg></div><span></span><span></span></div></div><div><div>    <label for=\"Ticket_888344_state_id\">Status <span>*</span></label></div></div></div>\n"
  //should = "<div>test 123</div>"
  should = '<div>Gruppe <span>*</span></div><div><div></div></div><div><div><span></span><span></span></div></div><div><div>Besitzer <span></span></div><div><div></div></div></div><div><div><div></div><span></span><span></span></div></div><div><div>    Status <span>*</span></div></div>'
  result = App.Utils.htmlRemoveRichtext(source)
  equal(result.html(), should, source)

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font><svg><use xlink:href=\"assets/images/icons.svg#icon-status\"></svg></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  result = App.Utils.htmlRemoveRichtext(source)
  equal(result.html(), should, source)

});

// htmlCleanup
test("htmlCleanup", function() {

  var source = "<div><!--test comment--><a href=\"test\">test</a></div>"
  //var should = "<div>test</div>"
  var should = "test"
  var result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><h1>some link to somewhere</h1></div>"
  //should = "<div><div>some link to somewhere</div></div>"
  should = "<div>some link to somewhere</div>"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><small>some link to somewhere</small></a>"
  //should = "<div>some link to somewhere</div>"
  should = "some link to somewhere"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><time>some link to somewhere</time></a>"
  //should = "<div>some link to somewhere</div>"
  should = "some link to somewhere"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><h1>some h1 for somewhere</h1><p><hr></p></div>"
  //should = "<div><div>some h1 for somewhere</div><p></p><p></p></div>"
  should = "<div>some h1 for somewhere</div><p></p><p></p>"
  //should = '<div>some h1 for somewhere</div>'
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><br></div>"
  //should = "<div><br></div>"
  should = "<br>"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><div class=\"xxx\"><br></div></div>"
  //should = "<div><div><br></div></div>"
  should = "<div><br></div>"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><form class=\"xxx\">test 123</form></div>"
  //should = "<div>test 123<br></div>"
  should = "test 123"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><form class=\"xxx\">test 123</form> some other value</div>"
  //should = "<div>test 123 some other value</div>"
  should = "test 123 some other value"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><form class=\"xxx\">test 123</form> some other value<input value=\"should not be shown\"></div>"
  //should = "<div>test 123 some other value</div>"
  should = "test 123 some other value"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font><svg><use xlink:href=\"assets/images/icons.svg#icon-status\"></svg></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><p>some link to somewhere from word<w:sdt>abc</w:sdt></p><o:p></o:p></a>"
  //should = "<div><p>some link to somewhere from wordabc</p></div>"
  should = '<p>some link to somewhere from wordabc</p>'
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><div><label for=\"Ticket_888344_group_id\">Gruppe <span>*</span></label></div><div><div></div></div><div><div><span></span><span></span></div></div><div><div><label for=\"Ticket_888344_owner_id\">Besitzer <span></span></label></div><div><div></div></div></div><div><div><div><svg><use xlink:href=\"http://localhost:3000/assets/images/icons.svg#icon-arrow-down\"></use></svg></div><span></span><span></span></div></div><div><div>    <label for=\"Ticket_888344_state_id\">Status <span>*</span></label></div></div></div>\n"
  //should = "<div>test 123</div>"
  should = '<div>Gruppe <span>*</span></div><div><div></div></div><div><div><span></span><span></span></div></div><div><div>Besitzer <span></span></div><div><div></div></div></div><div><div><div></div><span></span><span></span></div></div><div><div>    Status <span>*</span></div></div>'
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "<html xmlns:o=\"urn:schemas-microsoft-com:office:office\"\nxmlns:w=\"urn:schemas-microsoft-com:office:word\"\nxmlns:m=\"http://schemas.microsoft.com/office/2004/12/omml\"\nxmlns=\"http://www.w3.org/TR/REC-html40\">\n\n<head>\n<meta name=Titel content=\"\">\n<meta name=Stichwörter content=\"\">\n<meta http-equiv=Content-Type content=\"text/html; charset=utf-8\">\n<meta name=ProgId content=Word.Document>\n<meta name=Generator content=\"Microsoft Word 15\">\n<meta name=Originator content=\"Microsoft Word 15\">\n<link rel=File-List\nhref=\"file://localhost/Users/johannes/Library/Group%20Containers/UBF8T346G9.Office/msoclip1/01/clip_filelist.xml\">\n<!--[if gte mso 9]><xml>\n <o:OfficeDocumentSettings>\n  <o:AllowPNG/>\n  <o:PixelsPerInch>96</o:PixelsPerInch>\n </o:OfficeDocumentSettings>\n</xml><![endif]-->\n<link rel=themeData\nhref=\"file://localhost/Users/johannes/Library/Group%20Containers/UBF8T346G9.Office/msoclip1/01/clip_themedata.thmx\">\n<!--[if gte mso 9]><xml>\n <w:WordDocument>\n  <w:View>Normal</w:View>\n  <w:Zoom>0</w:Zoom>\n  <w:TrackMoves/>\n  <w:TrackFormatting/>\n  <w:HyphenationZone>21</w:HyphenationZone>\n  <w:PunctuationKerning/>\n  <w:ValidateAgainstSchemas/>\n  <w:SaveIfXMLInvalid>false</w:SaveIfXMLInvalid>\n  <w:IgnoreMixedContent>false</w:IgnoreMixedContent>\n  <w:AlwaysShowPlaceholderText>false</w:AlwaysShowPlaceholderText>\n  <w:DoNotPromoteQF/>\n  <w:LidThemeOther>DE</w:LidThemeOther>\n  <w:LidThemeAsian>X-NONE</w:LidThemeAsian>\n  <w:LidThemeComplexScript>X-NONE</w:LidThemeComplexScript>\n  <w:Compatibility>\n   <w:BreakWrappedTables/>\n   <w:SnapToGridInCell/>\n   <w:WrapTextWithPunct/>\n   <w:UseAsianBreakRules/>\n   <w:DontGrowAutofit/>\n   <w:SplitPgBreakAndParaMark/>\n   <w:EnableOpenTypeKerning/>\n   <w:DontFlipMirrorIndents/>\n   <w:OverrideTableStyleHps/>\n  </w:Compatibility>\n  <m:mathPr>\n   <m:mathFont m:val=\"Cambria Math\"/>\n   <m:brkBin m:val=\"before\"/>\n   <m:brkBinSub m:val=\"&#45;-\"/>\n   <m:smallFrac m:val=\"off\"/>\n   <m:dispDef/>\n   <m:lMargin m:val=\"0\"/>\n   <m:rMargin m:val=\"0\"/>\n   <m:defJc m:val=\"centerGroup\"/>\n   <m:wrapIndent m:val=\"1440\"/>\n   <m:intLim m:val=\"subSup\"/>\n   <m:naryLim m:val=\"undOvr\"/>\n  </m:mathPr></w:WordDocument>\n</xml><![endif]--><!--[if gte mso 9]><xml>\n <w:LatentStyles DefLockedState=\"false\" DefUnhideWhenUsed=\"false\"\n  DefSemiHidden=\"false\" DefQFormat=\"false\" DefPriority=\"99\"\n  LatentStyleCount=\"380\">\n  <w:LsdException Locked=\"false\" Priority=\"0\" QFormat=\"true\" Name=\"Normal\"/>\n  <w:LsdException Locked=\"false\" Priority=\"0\" QFormat=\"true\" Name=\"heading 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"0\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"0\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"0\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"0\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"9\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"9\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 7\"/>\n  <w:LsdException Locked=\"false\" Priority=\"9\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 8\"/>\n  <w:LsdException Locked=\"false\" Priority=\"9\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"heading 9\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 6\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 7\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 8\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index 9\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 7\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 8\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"toc 9\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Normal Indent\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"footnote text\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"annotation text\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"header\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"footer\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"index heading\"/>\n  <w:LsdException Locked=\"false\" Priority=\"35\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"caption\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"table of figures\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"envelope address\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"envelope return\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"footnote reference\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"annotation reference\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"line number\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"page number\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"endnote reference\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"endnote text\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"table of authorities\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"macro\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"toa heading\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Bullet\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Number\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Bullet 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Bullet 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Bullet 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Bullet 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Number 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Number 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Number 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Number 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"10\" QFormat=\"true\" Name=\"Title\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Closing\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Signature\"/>\n  <w:LsdException Locked=\"false\" Priority=\"1\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"Default Paragraph Font\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text Indent\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Continue\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Continue 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Continue 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Continue 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"List Continue 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Message Header\"/>\n  <w:LsdException Locked=\"false\" Priority=\"11\" QFormat=\"true\" Name=\"Subtitle\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Salutation\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Date\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text First Indent\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text First Indent 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Heading\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text Indent 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Body Text Indent 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Block Text\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Hyperlink\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"FollowedHyperlink\"/>\n  <w:LsdException Locked=\"false\" Priority=\"22\" QFormat=\"true\" Name=\"Strong\"/>\n  <w:LsdException Locked=\"false\" Priority=\"20\" QFormat=\"true\" Name=\"Emphasis\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Document Map\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Plain Text\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"E-mail Signature\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Top of Form\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Bottom of Form\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Normal (Web)\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Acronym\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Address\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Cite\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Code\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Definition\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Keyboard\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Preformatted\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Sample\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Typewriter\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"HTML Variable\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Normal Table\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"annotation subject\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"No List\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Outline List 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Outline List 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Outline List 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Simple 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Simple 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Simple 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Classic 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Classic 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Classic 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Classic 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Colorful 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Colorful 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Colorful 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Columns 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Columns 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Columns 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Columns 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Columns 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 6\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 7\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Grid 8\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 6\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 7\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table List 8\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table 3D effects 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table 3D effects 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table 3D effects 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Contemporary\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Elegant\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Professional\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Subtle 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Subtle 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Web 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Web 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Web 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Balloon Text\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" Name=\"Table Grid\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Table Theme\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 2\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 3\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 4\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 5\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 6\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 7\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 8\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" UnhideWhenUsed=\"true\"\n   Name=\"Note Level 9\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" Name=\"Placeholder Text\"/>\n  <w:LsdException Locked=\"false\" Priority=\"1\" QFormat=\"true\" Name=\"No Spacing\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1 Accent 1\"/>\n  <w:LsdException Locked=\"false\" SemiHidden=\"true\" Name=\"Revision\"/>\n  <w:LsdException Locked=\"false\" Priority=\"34\" QFormat=\"true\"\n   Name=\"List Paragraph\"/>\n  <w:LsdException Locked=\"false\" Priority=\"29\" QFormat=\"true\" Name=\"Quote\"/>\n  <w:LsdException Locked=\"false\" Priority=\"30\" QFormat=\"true\"\n   Name=\"Intense Quote\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"60\" Name=\"Light Shading Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"61\" Name=\"Light List Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"62\" Name=\"Light Grid Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"63\" Name=\"Medium Shading 1 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"64\" Name=\"Medium Shading 2 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"65\" Name=\"Medium List 1 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"66\" Name=\"Medium List 2 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"67\" Name=\"Medium Grid 1 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"68\" Name=\"Medium Grid 2 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"69\" Name=\"Medium Grid 3 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"70\" Name=\"Dark List Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"71\" Name=\"Colorful Shading Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"72\" Name=\"Colorful List Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"73\" Name=\"Colorful Grid Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"19\" QFormat=\"true\"\n   Name=\"Subtle Emphasis\"/>\n  <w:LsdException Locked=\"false\" Priority=\"21\" QFormat=\"true\"\n   Name=\"Intense Emphasis\"/>\n  <w:LsdException Locked=\"false\" Priority=\"31\" QFormat=\"true\"\n   Name=\"Subtle Reference\"/>\n  <w:LsdException Locked=\"false\" Priority=\"32\" QFormat=\"true\"\n   Name=\"Intense Reference\"/>\n  <w:LsdException Locked=\"false\" Priority=\"33\" QFormat=\"true\" Name=\"Book Title\"/>\n  <w:LsdException Locked=\"false\" Priority=\"37\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" Name=\"Bibliography\"/>\n  <w:LsdException Locked=\"false\" Priority=\"39\" SemiHidden=\"true\"\n   UnhideWhenUsed=\"true\" QFormat=\"true\" Name=\"TOC Heading\"/>\n  <w:LsdException Locked=\"false\" Priority=\"41\" Name=\"Plain Table 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"42\" Name=\"Plain Table 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"43\" Name=\"Plain Table 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"44\" Name=\"Plain Table 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"45\" Name=\"Plain Table 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"40\" Name=\"Grid Table Light\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\" Name=\"Grid Table 1 Light\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\" Name=\"Grid Table 6 Colorful\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\" Name=\"Grid Table 7 Colorful\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"Grid Table 1 Light Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"Grid Table 6 Colorful Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"Grid Table 7 Colorful Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"Grid Table 1 Light Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"Grid Table 6 Colorful Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"Grid Table 7 Colorful Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"Grid Table 1 Light Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"Grid Table 6 Colorful Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"Grid Table 7 Colorful Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"Grid Table 1 Light Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"Grid Table 6 Colorful Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"Grid Table 7 Colorful Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"Grid Table 1 Light Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"Grid Table 6 Colorful Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"Grid Table 7 Colorful Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"Grid Table 1 Light Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"Grid Table 2 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"Grid Table 3 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"Grid Table 4 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"Grid Table 5 Dark Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"Grid Table 6 Colorful Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"Grid Table 7 Colorful Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\" Name=\"List Table 1 Light\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\" Name=\"List Table 6 Colorful\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\" Name=\"List Table 7 Colorful\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"List Table 1 Light Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"List Table 6 Colorful Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"List Table 7 Colorful Accent 1\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"List Table 1 Light Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"List Table 6 Colorful Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"List Table 7 Colorful Accent 2\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"List Table 1 Light Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"List Table 6 Colorful Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"List Table 7 Colorful Accent 3\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"List Table 1 Light Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"List Table 6 Colorful Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"List Table 7 Colorful Accent 4\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"List Table 1 Light Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"List Table 6 Colorful Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"List Table 7 Colorful Accent 5\"/>\n  <w:LsdException Locked=\"false\" Priority=\"46\"\n   Name=\"List Table 1 Light Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"47\" Name=\"List Table 2 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"48\" Name=\"List Table 3 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"49\" Name=\"List Table 4 Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"50\" Name=\"List Table 5 Dark Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"51\"\n   Name=\"List Table 6 Colorful Accent 6\"/>\n  <w:LsdException Locked=\"false\" Priority=\"52\"\n   Name=\"List Table 7 Colorful Accent 6\"/>\n </w:LatentStyles>\n</xml><![endif]-->\n<style>\n<!--\n /* Font Definitions */\n@font-face\n {font-family:\"Courier New\";\n panose-1:2 7 3 9 2 2 5 2 4 4;\n mso-font-charset:0;\n mso-generic-font-family:auto;\n mso-font-pitch:variable;\n  mso-font-signature:-536859905 -1073711037 9 0 511 0;}\n@font-face\n {font-family:Wingdings;\n panose-1:5 0 0 0 0 0 0 0 0 0;\n mso-font-charset:2;\n mso-generic-font-family:auto;\n mso-font-pitch:variable;\n  mso-font-signature:0 268435456 0 0 -2147483648 0;}\n@font-face\n  {font-family:\"Cambria Math\";\n  panose-1:2 4 5 3 5 4 6 3 2 4;\n mso-font-charset:0;\n mso-generic-font-family:auto;\n mso-font-pitch:variable;\n  mso-font-signature:-536870145 1107305727 0 0 415 0;}\n@font-face\n  {font-family:Calibri;\n panose-1:2 15 5 2 2 2 4 3 2 4;\n  mso-font-charset:0;\n mso-generic-font-family:auto;\n mso-font-pitch:variable;\n  mso-font-signature:-536870145 1073786111 1 0 415 0;}\n /* Style Definitions */\np.MsoNormal, li.MsoNormal, div.MsoNormal\n  {mso-style-unhide:no;\n mso-style-qformat:yes;\n  mso-style-parent:\"\";\n  margin:0cm;\n margin-bottom:.0001pt;\n  mso-pagination:widow-orphan;\n  font-size:12.0pt;\n font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-fareast-font-family:Calibri;\n  mso-fareast-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-bidi-font-family:\"Times New Roman\";\n mso-bidi-theme-font:minor-bidi;\n mso-fareast-language:EN-US;}\np.MsoListParagraph, li.MsoListParagraph, div.MsoListParagraph\n {mso-style-priority:34;\n mso-style-unhide:no;\n  mso-style-qformat:yes;\n  margin-top:0cm;\n margin-right:0cm;\n margin-bottom:0cm;\n  margin-left:36.0pt;\n margin-bottom:.0001pt;\n  mso-add-space:auto;\n mso-pagination:widow-orphan;\n  font-size:12.0pt;\n font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-fareast-font-family:Calibri;\n  mso-fareast-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-bidi-font-family:\"Times New Roman\";\n mso-bidi-theme-font:minor-bidi;\n mso-fareast-language:EN-US;}\np.MsoListParagraphCxSpFirst, li.MsoListParagraphCxSpFirst, div.MsoListParagraphCxSpFirst\n  {mso-style-priority:34;\n mso-style-unhide:no;\n  mso-style-qformat:yes;\n  mso-style-type:export-only;\n margin-top:0cm;\n margin-right:0cm;\n margin-bottom:0cm;\n  margin-left:36.0pt;\n margin-bottom:.0001pt;\n  mso-add-space:auto;\n mso-pagination:widow-orphan;\n  font-size:12.0pt;\n font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-fareast-font-family:Calibri;\n  mso-fareast-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-bidi-font-family:\"Times New Roman\";\n mso-bidi-theme-font:minor-bidi;\n mso-fareast-language:EN-US;}\np.MsoListParagraphCxSpMiddle, li.MsoListParagraphCxSpMiddle, div.MsoListParagraphCxSpMiddle\n {mso-style-priority:34;\n mso-style-unhide:no;\n  mso-style-qformat:yes;\n  mso-style-type:export-only;\n margin-top:0cm;\n margin-right:0cm;\n margin-bottom:0cm;\n  margin-left:36.0pt;\n margin-bottom:.0001pt;\n  mso-add-space:auto;\n mso-pagination:widow-orphan;\n  font-size:12.0pt;\n font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-fareast-font-family:Calibri;\n  mso-fareast-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-bidi-font-family:\"Times New Roman\";\n mso-bidi-theme-font:minor-bidi;\n mso-fareast-language:EN-US;}\np.MsoListParagraphCxSpLast, li.MsoListParagraphCxSpLast, div.MsoListParagraphCxSpLast\n {mso-style-priority:34;\n mso-style-unhide:no;\n  mso-style-qformat:yes;\n  mso-style-type:export-only;\n margin-top:0cm;\n margin-right:0cm;\n margin-bottom:0cm;\n  margin-left:36.0pt;\n margin-bottom:.0001pt;\n  mso-add-space:auto;\n mso-pagination:widow-orphan;\n  font-size:12.0pt;\n font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-fareast-font-family:Calibri;\n  mso-fareast-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-bidi-font-family:\"Times New Roman\";\n mso-bidi-theme-font:minor-bidi;\n mso-fareast-language:EN-US;}\n.MsoChpDefault\n  {mso-style-type:export-only;\n  mso-default-props:yes;\n  font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-fareast-font-family:Calibri;\n  mso-fareast-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-bidi-font-family:\"Times New Roman\";\n mso-bidi-theme-font:minor-bidi;\n mso-fareast-language:EN-US;}\n@page WordSection1\n  {size:595.0pt 842.0pt;\n  margin:70.85pt 70.85pt 2.0cm 70.85pt;\n mso-header-margin:35.4pt;\n mso-footer-margin:35.4pt;\n mso-paper-source:0;}\ndiv.WordSection1\n  {page:WordSection1;}\n /* List Definitions */\n@list l0\n {mso-list-id:240799396;\n mso-list-type:hybrid;\n mso-list-template-ids:1377200210 67567617 67567619 67567621 67567617 67567619 67567621 67567617 67567619 67567621;}\n@list l0:level1\n  {mso-level-number-format:bullet;\n  mso-level-text:;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:Symbol;}\n@list l0:level2\n {mso-level-number-format:bullet;\n  mso-level-text:o;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:\"Courier New\";}\n@list l0:level3\n  {mso-level-number-format:bullet;\n  mso-level-text:;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:Wingdings;}\n@list l0:level4\n  {mso-level-number-format:bullet;\n  mso-level-text:;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:Symbol;}\n@list l0:level5\n {mso-level-number-format:bullet;\n  mso-level-text:o;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:\"Courier New\";}\n@list l0:level6\n  {mso-level-number-format:bullet;\n  mso-level-text:;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:Wingdings;}\n@list l0:level7\n  {mso-level-number-format:bullet;\n  mso-level-text:;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:Symbol;}\n@list l0:level8\n {mso-level-number-format:bullet;\n  mso-level-text:o;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:\"Courier New\";}\n@list l0:level9\n  {mso-level-number-format:bullet;\n  mso-level-text:;\n mso-level-tab-stop:none;\n  mso-level-number-position:left;\n text-indent:-18.0pt;\n  font-family:Wingdings;}\nol\n {margin-bottom:0cm;}\nul\n  {margin-bottom:0cm;}\n-->\n</style>\n<!--[if gte mso 10]>\n<style>\n /* Style Definitions */\ntable.MsoNormalTable\n  {mso-style-name:\"Normale Tabelle\";\n  mso-tstyle-rowband-size:0;\n  mso-tstyle-colband-size:0;\n  mso-style-noshow:yes;\n mso-style-priority:99;\n  mso-style-parent:\"\";\n  mso-padding-alt:0cm 5.4pt 0cm 5.4pt;\n  mso-para-margin:0cm;\n  mso-para-margin-bottom:.0001pt;\n mso-pagination:widow-orphan;\n  font-size:12.0pt;\n font-family:Calibri;\n  mso-ascii-font-family:Calibri;\n  mso-ascii-theme-font:minor-latin;\n mso-hansi-font-family:Calibri;\n  mso-hansi-theme-font:minor-latin;\n mso-fareast-language:EN-US;}\n</style>\n<![endif]-->\n</head>\n\n<body bgcolor=white lang=DE style='tab-interval:35.4pt'>\n<!--StartFragment-->\n\n<p class=MsoListParagraphCxSpFirst style='text-indent:-18.0pt;mso-list:l0 level1 lfo1'><![if !supportLists]><span\nstyle='font-family:Symbol;mso-fareast-font-family:Symbol;mso-bidi-font-family:\nSymbol'><span style='mso-list:Ignore'>·<span style='font:7.0pt \"Times New Roman\"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n</span></span></span><![endif]>Test 1<o:p></o:p></p>\n\n<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt;mso-list:l0 level1 lfo1'><![if !supportLists]><span\nstyle='font-family:Symbol;mso-fareast-font-family:Symbol;mso-bidi-font-family:\nSymbol'><span style='mso-list:Ignore'>·<span style='font:7.0pt \"Times New Roman\"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n</span></span></span><![endif]>Test 2<o:p></o:p></p>\n\n<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt;mso-list:l0 level1 lfo1'><![if !supportLists]><span\nstyle='font-family:Symbol;mso-fareast-font-family:Symbol;mso-bidi-font-family:\nSymbol'><span style='mso-list:Ignore'>·<span style='font:7.0pt \"Times New Roman\"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n</span></span></span><![endif]><i style='mso-bidi-font-style:normal'>Test 3<o:p></o:p></i></p>\n\n<p class=MsoListParagraphCxSpMiddle style='text-indent:-18.0pt;mso-list:l0 level1 lfo1'><![if !supportLists]><span\nstyle='font-family:Symbol;mso-fareast-font-family:Symbol;mso-bidi-font-family:\nSymbol'><span style='mso-list:Ignore'>·<span style='font:7.0pt \"Times New Roman\"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n</span></span></span><![endif]>Test 4<o:p></o:p></p>\n\n<p class=MsoListParagraphCxSpLast style='text-indent:-18.0pt;mso-list:l0 level1 lfo1'><![if !supportLists]><span\nstyle='font-family:Symbol;mso-fareast-font-family:Symbol;mso-bidi-font-family:\nSymbol'><span style='mso-list:Ignore'>·<span style='font:7.0pt \"Times New Roman\"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n</span></span></span><![endif]><b style='mso-bidi-font-weight:normal'>Test5<o:p></o:p></b></p>\n\n<!--EndFragment-->\n</body>\n\n</html>"
  should = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n<p>·            \nTest 1</p>\n\n<p>·            \nTest 2</p>\n\n<p>·            \n<i>Test 3</i></p>\n\n<p>·            \nTest 4</p>\n\n<p>·            \n<b>Test5</b></p>\n\n\n\n\n"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n<html>\n<head>\n  <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>\n  <title></title>\n  <meta name=\"generator\" content=\"LibreOffice 4.4.7.2 (MacOSX)\"/>\n  <style type=\"text/css\">\n    @page { margin: 0.79in }\n    p { margin-bottom: 0.1in; line-height: 120% }\n    a:link { so-language: zxx }\n  </style>\n</head>\n<body lang=\"en-US\" dir=\"ltr\">\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">1.\nGehe a<b>uf </b><b>https://www.pfe</b>rdiathek.ge</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\"><br/>\n\n</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">2.\nMel<font color=\"#800000\">de Dich mit folgende</font> Zugangsdaten an:</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">Benutzer:\nme@xxx.net</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">Passwort:\nxxx.</p>\n</body>\n</html>"
  should = "\n\n\n  \n  \n  \n  \n\n\n<p align=\"center\">1.\nGehe a<b>uf </b><b>https://www.pfe</b>rdiathek.ge</p>\n<p align=\"center\"><br>\n\n</p>\n<p align=\"center\">2.\nMelde Dich mit folgende Zugangsdaten an:</p>\n<p align=\"center\">Benutzer:\nme@xxx.net</p>\n<p align=\"center\">Passwort:\nxxx.</p>\n\n"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

});

// wrap
test("wrap", function() {

  var source = "some text"
  var should = 'some text'
  var result = App.Utils.wrap(source)
  equal(result, should, source)

  source = "some text\nsome other text\n"
  should = "some text\nsome other text\n"
  result = App.Utils.wrap(source)
  equal(result, should, source)

  source = "some text with some line to wrap"
  should = "some text with\nsome line to\nwrap"
  result = App.Utils.wrap(source, 14)
  equal(result, should, source)

  source = "some text\nsome other text\n"
  should = "some text\nsome other text\n"
  result = App.Utils.wrap(source)
  equal(result, should, source)

  source = "1234567890 1234567890 1234567890 1234567890"
  should = "1234567890 1234567890 1234567890 1234567890"
  result = App.Utils.wrap(source)
  equal(result, should, source)

  source = "123456789012 123456789012 123456789012"
  should = "123456789012\n123456789012\n123456789012"
  result = App.Utils.wrap(source, 14)
  equal(result, should, source)

});

// remove empty lines
test("remove empty lines", function() {

  var source = "\ntest 123\n"
  var should = "test 123\n"
  var result = App.Utils.removeEmptyLines(source)
  equal(result, should, source)

  source = "\ntest\n\n123\n"
  should = "test\n123\n"
  result = App.Utils.removeEmptyLines(source)
  equal(result, should, source)

});

// quote
test("quote", function() {

  var source = "some text"
  var should = '> some text'
  var result = App.Utils.quote(source)
  equal(result, should, source)

  source = "some text\nsome other text\n"
  should = "> some text\n> some other text"
  result = App.Utils.quote(source)
  equal(result, should, source)

  source = "\n\nsome text\nsome other text\n \n"
  should = "> some text\n> some other text"
  result = App.Utils.quote(source)
  equal(result, should, source)

  source = "Welcome!\n\nThank you for installing Zammad.\n\nYou will find ..."
  should = "> Welcome!\n>\n> Thank you for installing Zammad.\n>\n> You will find ..."
  result = App.Utils.quote(source)
  equal(result, should, source)

  source = "Welcome! Thank you for installing Zammad. You will find ..."
  should = "> Welcome! Thank you\n> for installing\n> Zammad. You will\n> find ..."
  result = App.Utils.quote(source, 20)
  equal(result, should, source)

});

// check signature
test("check signature", function() {

  var message   = "<div>test 123 </div>"
  var signature = '<div>--<br>Some Signature<br>some department</div>'
  var result    = App.Utils.signatureCheck(message, signature)
  equal(result, true)

  message   = "<div>test 123 <div>--<br>Some Signature<br>some department\n</div></div>"
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck(message, signature)
  equal(result, false)

  message   = "<div>test 123 <div>--<br>Some Signature\n<br>some department\n</div></div>"
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck(message, signature)
  equal(result, false)

  message   = "<div>test 123 <div>--<p>Some Signature</p>\n<p><div>some department</div>\n</p>\n</div></div>"
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck(message, signature)
  equal(result, false)

  message   = ""
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck(message, signature)
  equal(result, true)

  message   = ""
  signature = "--\nSome Signature\nsome department"
  result    = App.Utils.signatureCheck(message, signature)
  equal(result, true)

});

// identify signature
test("identify signature", function() {

  var message = "<div>test 123 </div>"
  var should  = '<div>test 123 </div>'
  var result  = App.Utils.signatureIdentify(message)
  equal(result, should)

  message = "<div>test 123 <br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentify(message)
  equal(result, should)

  message = "<div>test 123 <br/>1<br/>2<br/>3<br/>4<br/>5<br/>6<br/>7<br/>8<br/>9<br/><br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/>1<br/>2<br/>3<br/>4<br/>5<br/>6<br/>7<br/>8<br/>9<br/><br/><span class="js-signatureMarker"></span>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentify(message)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><span class="js-signatureMarker"></span>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/> -- <br/>Bob Smith</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><span class="js-signatureMarker"></span> -- <br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--<br/>Bob Smith<br/><br/><br/><br/><br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/><br/><span class="js-signatureMarker"></span>--<br/>Bob Smith<br/><br/><br/><br/><br/>--<br/>Bob Smith</div>'
  //should  = '<div>test 123 <br><br><br><br><br><br><br><br><br><br><br><span class="js-signatureMarker"></span>--<br>Bob Smith<br/><br/><br/><br/><br/>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123</div><div>test 123</div><div>--</div><div>Bob Smith</div>"
  should  = "<div>test 123</div><div>test 123</div><div><span class=\"js-signatureMarker\"></span>--</div><div>Bob Smith</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<p><span>test 123</span></p><p><span>test 123</span></p><p><span>--</span></p><p><span>Bob Smith</span></p><div></div>"
  should  = "<p><span>test 123</span></p><p><span>test 123</span></p><p><span><span class=\"js-signatureMarker\"></span>--</span></p><p><span>Bob Smith</span></p><div></div>"
  result  = App.Utils.signatureIdentify(message, true)

  // apple
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>On 01/04/15 10:55, Bob Smith wrote:<br/>lalala<p>--</p>some test</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>On 01/04/15 10:55, Bob Smith wrote:<br/>lalala<p>--</p>some test</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Am 03.04.2015 um 20:58 schrieb Bob Smith &lt;bob@example.com&gt;:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Am 03.04.2015 um 20:58 schrieb Bob Smith &lt;bob@example.com&gt;:<br/>lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // ms
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>Subject: lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>Subject: lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>1<br/>2<br/>3<br/>4<br/>4<br/>Subject: lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>1<br/>2<br/>3<br/>4<br/>4<br/>Subject: lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Gesendet: Donnerstag, 2. April 2015 10:00<br/>Betreff: lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Gesendet: Donnerstag, 2. April 2015 10:00<br/>Betreff: lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div>"
  should  = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  should  = "<div>1<br><br></div><div><span class=\"js-signatureMarker\"></span>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support &lt;<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>&gt;</div>\n<div>An: somebody</div><div>Datum: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  should  = "<div>1<br><br></div><div><span class=\"js-signatureMarker\"></span>Von: Martin Edenhofer via Znuny Support &lt;<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>&gt;</div>\n<div>An: somebody</div><div>Datum: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>Von: &quot;Johannes Nickel via Znuny Projects&quot; &lt;<a href=\"mailto:projects@znuny.inc\" title=\"mailto:projects@znuny.inc\">projects@znuny.inc</a>&gt;</div><div>An: \"Lisa Smith\" &lt;<a href=\"mailto:lisa.smith@example.com\" title=\"mailto:lisa.smith@example.com\">lisa.smith@example.com</a>&gt;</div><div>Gesendet: Donnerstag, 2. April 2015 10:11:12</div><div>Betreff: Angebot Redundanz / Paket mit Silver Subscription [Ticket#424242]</div><div><br></div><div>Hallo Frau Smith,</div>"
  should  = "<div><span class=\"js-signatureMarker\"></span>Von: &quot;Johannes Nickel via Znuny Projects&quot; &lt;<a href=\"mailto:projects@znuny.inc\" title=\"mailto:projects@znuny.inc\">projects@znuny.inc</a>&gt;</div><div>An: \"Lisa Smith\" &lt;<a href=\"mailto:lisa.smith@example.com\" title=\"mailto:lisa.smith@example.com\">lisa.smith@example.com</a>&gt;</div><div>Gesendet: Donnerstag, 2. April 2015 10:11:12</div><div>Betreff: Angebot Redundanz / Paket mit Silver Subscription [Ticket#424242]</div><div><br></div><div>Hallo Frau Smith,</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>Hi Johannes,</div><div><br></div><div>das Angebot für den halben Tag bitte an uns.</div><div>Der Termin hat sich jetzt auf 10-12 Uhr verschoben, hab ich dir weitergeleitet.</div><div><br></div><div>Viele Grüße</div><div>Max</div><div><br></div><div>&gt; On 07 Oct 2015, at 11:55, Johannes Smith &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>smith@example.com</a> &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>mailto:smith@example.com</a>&gt;&gt; wrote:</div><div>&gt;</div><div>&gt; Hi,</div><div>&gt;</div><div>&gt; OK. Wer kriegt das Angebot? Ist das wirklich nur ein halber Tag?</div></div>"
  should  = "<div>Hi Johannes,</div><div><br></div><div>das Angebot für den halben Tag bitte an uns.</div><div>Der Termin hat sich jetzt auf 10-12 Uhr verschoben, hab ich dir weitergeleitet.</div><div><br></div><div>Viele Grüße</div><div>Max</div><div><br></div><div><span class=\"js-signatureMarker\"></span>&gt; On 07 Oct 2015, at 11:55, Johannes Smith &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>smith@example.com</a> &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>mailto:smith@example.com</a>&gt;&gt; wrote:</div><div>&gt;</div><div>&gt; Hi,</div><div>&gt;</div><div>&gt; OK. Wer kriegt das Angebot? Ist das wirklich nur ein halber Tag?</div></div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "Dear Mr. Smith,<div><br></div><div>it seems to be, dass Sie den AutoIncrement Nummerngenerator für Ihre ITSMChangeManagement Installation verwenden. Seit ABC 3.2 wird führend vor der sich in der Datei&nbsp;<span style=\"line-height: 1.45; background-color: initial;\">&lt;ABC_CONFIG_Home&gt;/war/log/ITSMChangeCounter.log &nbsp;befindenden Zahl die SystemID (SysConfig) geschrieben. Dies ist ein Standardverhalten, dass auch bei der Ticketnummer verwendet wird.<br><br>Please ask me if you have questions.</span></div><div><span style=\"line-height: 1.45; background-color: initial;\"><br></span></div><div><span style=\"line-height: 1.45; background-color: initial;\">Viele Grüße,</span></div><div><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n<br>Enterprise Services for ABC\n<br>\n<br>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany\n<br>\n<br>P: +49 (0) 30 111 111 111-0\n<br>F: +49 (0) 30 111 111 111-8\n<br>W: http://znuny.com \n<br>\n<br>Location: Berlin - HRB 12345678 B Amtsgericht Berlin-Charlottenburg\n<br>Managing Director: Martin Edenhofer\n<br></div></div>"
  should  = "Dear Mr. Smith,<div><br></div><div>it seems to be, dass Sie den AutoIncrement Nummerngenerator für Ihre ITSMChangeManagement Installation verwenden. Seit ABC 3.2 wird führend vor der sich in der Datei&nbsp;<span style=\"line-height: 1.45; background-color: initial;\">&lt;ABC_CONFIG_Home&gt;/war/log/ITSMChangeCounter.log &nbsp;befindenden Zahl die SystemID (SysConfig) geschrieben. Dies ist ein Standardverhalten, dass auch bei der Ticketnummer verwendet wird.<br><br>Please ask me if you have questions.</span></div><div><span style=\"line-height: 1.45; background-color: initial;\"><br></span></div><div><span style=\"line-height: 1.45; background-color: initial;\">Viele Grüße,</span></div><div><span class=\"js-signatureMarker\"></span><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n<br>Enterprise Services for ABC\n<br>\n<br>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany\n<br>\n<br>P: +49 (0) 30 111 111 111-0\n<br>F: +49 (0) 30 111 111 111-8\n<br>W: http://znuny.com \n<br>\n<br>Location: Berlin - HRB 12345678 B Amtsgericht Berlin-Charlottenburg\n<br>Managing Director: Martin Edenhofer\n<br></div></div>"
  result  = App.Utils.signatureIdentify(message, true, true)
  equal(result, should)

  message = "Dear Mr. Smith, nice to read you,<div><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  should  = "Dear Mr. Smith, nice to read you,<div><span class=\"js-signatureMarker\"></span><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  result  = App.Utils.signatureIdentify(message, true, true)
  equal(result, should)

  message = "Dear Mr. Smith, nice to read you,<div><div data-signature=\"true\" data-signature-id=\"9999\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  should  = "Dear Mr. Smith, nice to read you,<div><div data-signature=\"true\" data-signature-id=\"9999\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  result  = App.Utils.signatureIdentify(message, false, true)
  equal(result, should)

  // fr
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Envoyé : mercredi 29 avril 2015 17:31<br/>Objet : lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Envoyé : mercredi 29 avril 2015 17:31<br/>Objet : lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // thunderbird
  // de
  message = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div>Am 04.03.2015 um 12:47 schrieb Martin Edenhofer via Znuny Sales:</div><div>&gt; Hallo Christian,</div>"
  should  = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div><span class=\"js-signatureMarker\"></span>Am 04.03.2015 um 12:47 schrieb Martin Edenhofer via Znuny Sales:</div><div>&gt; Hallo Christian,</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // en - Thunderbird default - http://kb.mozillazine.org/Reply_header_settings
  message = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div>On 01-01-2007 11:00 AM, Alf Aardvark wrote:</div><div>&gt; Hallo Christian,</div>"
  should  = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div><span class=\"js-signatureMarker\"></span>On 01-01-2007 11:00 AM, Alf Aardvark wrote:</div><div>&gt; Hallo Christian,</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // en - http://kb.mozillazine.org/Reply_header_settings
  message = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div>Alf Aardvark wrote, on 01-01-2007 11:00 AM:</div><div>&gt; Hallo Christian,</div>"
  should  = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div><span class=\"js-signatureMarker\"></span>Alf Aardvark wrote, on 01-01-2007 11:00 AM:</div><div>&gt; Hallo Christian,</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // otrs
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>01/04/15 10:55 - Bob Smith wrote:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>01/04/15 10:55 - Bob Smith wrote:<br/>lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>01/04/15 10:55 - Bob Smith schrieb:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>01/04/15 10:55 - Bob Smith schrieb:<br/>lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/></div><div>24.02.2015 14:20 - Roy Kaldung via Znuny Sales schrieb: &nbsp;</div>"
  should  = "<div>test 123 <br/><br/></div><div><span class=\"js-signatureMarker\"></span>24.02.2015 14:20 - Roy Kaldung via Znuny Sales schrieb: &nbsp;</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // zammad
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><div data-signature=\"true\" data-signature-id=\"5\">lalala</div></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><div data-signature=\"true\" data-signature-id=\"5\">lalala</div></div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><blockquote type=\"cite\">lalala</blockquote></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><blockquote type=\"cite\">lalala</blockquote></div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // gmail
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><blockquote class=\"ecxgmail_quote\">lalala</blockquote></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><blockquote class=\"ecxgmail_quote\">lalala</blockquote></div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><blockquote class=\"gmail_quote\">lalala</blockquote></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><blockquote class=\"gmail_quote\">lalala</blockquote></div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Am 24. Dezember 2015 um 07:45 schrieb kathrine &lt;kathrine@example.com&gt;:<br/>lalala</div>"
  should = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span>Am 24. Dezember 2015 um 07:45 schrieb kathrine &lt;kathrine@example.com&gt;:<br/>lalala</div>"
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // word 14
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Bob Smith wrote:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Bob Smith wrote:<br/>lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Bob Smith schrieb:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Bob Smith schrieb:<br/>lalala</div>'
  result  = App.Utils.signatureIdentify(message, true)
  equal(result, should)

});

// replace tags
test("check replace tags", function() {

  var message = "<div>#{user.firstname} #{user.lastname}</div>"
  var result  = '<div>Bob Smith</div>'
  var data    = {
    user: {
      firstname: 'Bob',
      lastname:  'Smith',
    },
  }
  var verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.lastname}</div>"
  result  = '<div>Bob Smith</div>'
  data    = {
    user: {
      firstname: function() { return 'Bob' },
      lastname:  function() { return 'Smith' },
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.lastname}</div>"
  result  = '<div>Bob </div>'
  data    = {
    user: {
      firstname: 'Bob',
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

});

// check if last line is a empty line
test("check if last line is a empty line", function() {

  var message = "123"
  var result  = false
  var verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div>123</div>"
  result  = false
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<p><div>123 </div></p>"
  result  = false
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div></div>"
  result  = true
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div class=\"some_class\"></div>"
  result  = true
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div class=\"some_class\"></div>  "
  result  = true
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div class=\"some_class\"></div>  \n  \n\t"
  result  = true
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div class=\"some_class\">  </div>  \n  \n\t"
  result  = true
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)

  message = "<div class=\"some_class\"\n>  \n</div>  \n  \n\t"
  result  = true
  verify  = App.Utils.lastLineEmpty(message)
  equal(verify, result, message)


});

// check attibute validation
test("check attibute validation", function() {

  var string = '123'
  var result = '123'
  var verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '123!'
  result = '123'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '12 3!'
  result = '123'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '12-3!'
  result = '12-3'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '12_3!'
  result = '12_3'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '^12_3!'
  result = '12_3'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '^1\n 2_3!'
  result = '12_3'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = 'abc?'
  result = 'abc'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = 'abc."'
  result = 'abc'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = '#abc!^'
  result = 'abc'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = 'abc()=$'
  result = 'abc'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

  string = "abc()=$\n123\rß"
  result = 'abc123'
  verify = App.Utils.htmlAttributeCleanup(string)
  equal(verify, result, string)

});

// check form diff
test("check form diff", function() {

  var dataNow = {
     owner_id:     1,
     pending_date: '2015-01-28T09:39:00Z',
  }
  var dataLast = {
     owner_id:     '',
     pending_date: '2015-01-28T09:39:00Z',
  }
  var diff = {}
  var result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
     owner_id:     '1',
     pending_date: '2015-01-28T09:39:00Z',
  }
  dataLast = {
     owner_id:     '',
     pending_date: '2015-01-28T09:39:00Z',
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
     pending_date: '2015-01-28T09:39:00Z',
  }
  dataLast = {
     owner_id:     1,
     pending_date: '2015-01-28T09:39:00Z',
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
     owner_id:     '',
     pending_date: '2015-01-28T09:39:00Z',
  }
  dataLast = {
     pending_date: '2015-01-28T09:39:00Z',
  }
  diff = {
    owner_id: '',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    owner_id:  '',
    state_ids: [1,5,6,7],
  }
  dataLast = {}
  diff = {
    owner_id:  '',
    state_ids: ['1','5','6','7'],
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    owner_id:  1,
    state_ids: [1,5,7,6],
  }
  dataLast = {
    owner_id:  '',
    state_ids: [1,5,6,7],
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
     owner_id:  1,
     state_ids: [1,5,6,7],
  }
  dataLast = {
    state_ids: ['1','5','7'],
  }
  diff = {
    owner_id:  '',
    state_ids: ['6'],
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
     owner_id:  '',
     state_ids: [1,5,6,7],
  }
  dataLast = {
    owner_id:  1,
    state_ids: [1,5,6,7],
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
     owner_id:  '',
     state_ids: [1,5,6,7],
  }
  dataLast = {
    owner_id:  5,
    state_ids: [1,5,6,7],
  }
  diff = {
    owner_id: ''
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    state_id:     4,
    pending_time: '2015-01-28T11:34:00Z'
  }
  dataLast = {
    state_id:     5,
    pending_time: undefined
  }
  diff = {
    state_id:     '4',
    pending_time: '2015-01-28T11:34:00Z'
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    pending_time: undefined
  }
  dataLast = {
    pending_time: null
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    ticket: {
      pending_time: undefined,
    },
  }
  dataLast = {
    ticket: {
      pending_time: null,
    },
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: '123',
    ticket: {
      pending_time: undefined,
    },
  }
  dataLast = {
    test: '123',
    ticket: {
      pending_time: null,
    },
  }
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: '123',
  }
  dataLast = {}
  diff = {
    test: '123',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: '123',
  }
  dataLast = {
    test: [1,2,3,4]
  }
  diff = {
    test: '123',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: '123',
  }
  dataLast = {
    test: {
      1: 1,
      2: 2,
    }
  }
  diff = {
    test: '123',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: [1,2,3,'4']
  }
  dataLast = {
    test: '123',
  }
  diff = {
    test: ['1','2','3','4']
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: {
      1: 1,
      2: 2,
    }
  }
  dataLast = {
    test: '123',
  }
  diff = {
    test: {
      1: '1',
      2: '2',
    }
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    test: '123',
    ticket: {
      pending_time: undefined,
    },
  }
  dataLast = {
    ticket: {
      pending_time: null,
    },
  }
  diff = {
    test: '123',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = undefined
  dataLast = undefined

  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {}
  dataLast = {"number":"10012","title":"some subject 123äöü","group_id":1,"owner_id":1,"customer_id":2,"state_id":3,"priority_id":2,"article":{"from":"Test Master Agent","to":"","cc":"","body":"dasdad","content_type":"text/html","ticket_id":12,"type_id":9,"sender_id":1,"internal":false,"form_id":"523405147"},"updated_at":"2015-01-29T09:22:23.000Z","pending_time":"2015-01-28T22:22:00.000Z","id":12}
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')

  // do not compare content of data instances/objects
  no = function test_object() {
    this.a = function() { return 123; }
    this.b = function() { return '1234'; }
    this.c = function() { return [123]; }
    this.d = [1,2,3];
    this.e = 'abc';
  }
  no1 = new no()
  no2 = new no()
  no3 = new no()

  dataNow = {
    number:'10013',
    Article: [no1],
  }
  dataLast = {
    number: "10012",
    title: "some subject 123äöü",
    Article: [ no2, no3 ],
  }
  diff = {
    number:'10013',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')

  dataNow = {
    number:'10013',
    Article: [no1,2],
  }
  dataLast = {
    number: "10012",
    title: "some subject 123äöü",
    Article: [ no2, no3 ],
  }
  diff = {
    number:'10013',
    Article: ['2'],
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')

});

// check decimal format
test("check decimal format", function() {

  var string = '123'
  var result = '123.00'
  var verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = '0.6'
  result = '0.60'
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = '6'
  result = '6.00'
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = 6.5
  result = '6.50'
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = '111111.6'
  result = '111111.60'
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = '111111.622'
  result = '111111.62'
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = 'abc.6'
  result = 'abc.6'
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = ''
  result = ''
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = undefined
  result = ''
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

  string = null
  result = ''
  verify = App.Utils.decimal(string)
  equal(verify, result, string)

});

// check formatTime format
test("check formatTime format", function() {

  var string = '123'
  var result = '123'
  var verify = App.Utils.formatTime(string, 0)
  equal(verify, result, string)

  string = '6'
  result = '06'
  verify = App.Utils.formatTime(string, 2)
  equal(verify, result, string)

  string = ''
  result = '00'
  verify = App.Utils.formatTime(string, 2)
  equal(verify, result, string)

  string = undefined
  result = ''
  verify = App.Utils.formatTime(string, 2)
  equal(verify, result, string)

  string = null
  result = ''
  verify = App.Utils.formatTime(string, 2)
  equal(verify, result, string)
});

}