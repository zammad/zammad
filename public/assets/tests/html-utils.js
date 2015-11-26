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

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font><svg><use xlink:href=\"assets/images/icons.svg#icon-status\"></svg></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext($(source))
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
  should = "<div><p>some link to somewhere from wordabc</p></div>"
  result = App.Utils.htmlCleanup($(source))
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