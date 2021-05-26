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

  source = "Some\nValue\n"
  should = "<div>Some</div><div>Value</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some\rValue\r"
  should = "<div>Some</div><div>Value</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some\n\rValue\n\r"
  should = "<div>Some</div><div>Value</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some\r\nValue\r\n"
  should = "<div>Some</div><div>Value</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some   Value 123"
  should = "<div>Some &nbsp; Value 123</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)

  source = "Some\n   Value\n    123"
  should = "<div>Some</div><div> &nbsp; Value</div><div> &nbsp; &nbsp;123</div>"
  result = App.Utils.text2html(source)
  equal(result, should, source)
});

// htmlStrip
test("htmlStrip", function() {

  var source = $('<div><br><b>lala</b></div>')
  var should = '<div><b>lala</b></div>'
  App.Utils.htmlStrip(source)
  equal(source.get(0).outerHTML, should)

  source = $('<div><br><br><br><b>lala</b></div>')
  should = '<div><b>lala</b></div>'
  App.Utils.htmlStrip(source)
  equal(source.get(0).outerHTML, should)

  source = $('<div><br><br><br><b>lala</b><br><br></div>')
  should = '<div><b>lala</b></div>'
  App.Utils.htmlStrip(source)
  equal(source.get(0).outerHTML, should)

  source = $('<div><br><br><div><br></div><b>lala</b><br><br></div>')
  should = '<div><div><br></div><b>lala</b></div>'
  App.Utils.htmlStrip(source)
  equal(source.get(0).outerHTML, should)

});

// lastLineEmpty
test("htmlLastLineEmpty", function() {

  var source = $('<div><br><b>lala</b></div>')
  equal(App.Utils.htmlLastLineEmpty(source), false)

  source = $('<div><br><b>lala</b><br></div>')
  equal(App.Utils.htmlLastLineEmpty(source), true)

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

  source = "<div>Some &amp; &lt;Value&gt;</div>"
  should = "Some & <Value>"
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

// phoneify
test("phoneify", function() {

  var source = "+1 123 123 123-123"
  var should = 'tel:+1123123123123'
  var result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "+1 123 123 A 123-123<>"
  should = 'tel:+1123123123123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "+1 (123) 123 123-123"
  should = 'tel:+1123123123123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "+1 (123) 123 1#23-123"
  should = 'tel:+11231231#23123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "+1 (123) 12*3 1#23-123"
  should = 'tel:+112312*31#23123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "+1 (123) 12+3"
  should = 'tel:+1123123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "+1 (123) 123 "
  should = 'tel:+1123123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)

  source = "  +1 (123) 123 "
  should = 'tel:+1123123'
  result = App.Utils.phoneify(source)
  equal(result, should, source)
})

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

  source = "test@example.com some text"
  should = 'test@example.com some text'
  result = App.Utils.linkify(source)
  equal(result, should, source)

  source = "abc test@example.com some text"
  should = 'abc test@example.com some text'
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

});

// htmlRemoveRichtext
test("htmlRemoveRichtext", function() {

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

  source = "<div><p wrap=\"\">test 123</p></div>"
  should = "<p>test 123</p>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font></div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext(source)
  equal(result.html(), should, source)

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
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.html(), should, source)

  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext(source)
  equal(result.html(), should, source)

  var source = "<div><!--test comment--><a href=\"test\">test</a></div>"
  var should = "<div>test</div>"
  var result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.get(0).outerHTML, should, source)

  source = "<div><small>some link to somewhere</small></a>"
  should = "<div>some link to somewhere</div>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.get(0).outerHTML, should, source)

  source = "<div><div class=\"xxx\"><br></div></div>"
  should = "<div><div><br></div></div>"
  result = App.Utils.htmlRemoveRichtext($(source))
  equal(result.get(0).outerHTML, should, source)

  source = "<div><table bgcolor=\"green\" aaa=\"1\"><thead><tr><th>111</th><th colspan=\"2\" abc=\"a\">aaa</th></tr></thead><tbody><tr><td>key</td><td>value</td></tr></tbody></table></div>"
  should = "<div>111aaakeyvalue</div>"
  result = App.Utils.htmlRemoveRichtext(source, true)
  equal(result.get(0).outerHTML, should, source)
});

// htmlCleanup
test("htmlCleanup", function() {

  var source = "<div><!--test comment--><a href=\"test\">test</a></div>"
  //var should = "<div>test</div>"
  var should = "<a href=\"test\">test</a>"
  var result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><!--test comment--><a href=\"test\">test</a></div>"
  should = "<a href=\"test\">test</a>"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "some link to somewhere"
  should = "some link to somewhere"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "<li>a</li><li>b</li>"
  should = "<li>a</li><li>b</li>"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<p><a href=\"some_link\">some link to somewhere</a><p>"
  should = "<a href=\"some_link\">some link to somewhere</a>"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><h1>some link to somewhere</h1></div>"
  should = "<h1>some link to somewhere</h1>"
  result = App.Utils.htmlCleanup($(source))
  equal(result.html(), should, source)

  source = "<div><p id=\"123\" data-id=\"abc\">some link to somewhere</p></div>"
  should = "<p>some link to somewhere</p>"
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
  should = "<h1>some h1 for somewhere</h1><p></p><hr><p></p>"
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
  should = "<font color=\"red\">This is some text!</font>"
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
  should = "<ul><li>Test 1</li><li>Test 2</li><li><i>Test 3</i></li><li>Test 4</li><li><b>Test5</b></li></ul>"
  result = App.Utils.htmlCleanup(source)
  equal(result.html().trim(), should, source)

  source = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n<html>\n<head>\n  <meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>\n  <title></title>\n  <meta name=\"generator\" content=\"LibreOffice 4.4.7.2 (MacOSX)\"/>\n  <style type=\"text/css\">\n    @page { margin: 0.79in }\n    p { margin-bottom: 0.1in; line-height: 120% }\n    a:link { so-language: zxx }\n  </style>\n</head>\n<body lang=\"en-US\" dir=\"ltr\">\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">1.\nGehe a<b>uf </b><b>https://www.pfe</b>rdiathek.ge</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\"><br/>\n\n</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">2.\nMel<font color=\"#800000\">de Dich mit folgende</font> Zugangsdaten an:</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">Benutzer:\nme@xxx.net</p>\n<p align=\"center\" style=\"margin-bottom: 0in; line-height: 100%\">Passwort:\nxxx.</p>\n</body>\n</html>"
  should = "\n\n\n  \n  \n  \n  \n\n\n<p>1.\nGehe a<b>uf </b><b>https://www.pfe</b>rdiathek.ge</p>\n<p><br>\n\n</p>\n<p>2.\nMel<font color=\"#800000\">de Dich mit folgende</font> Zugangsdaten an:</p>\n<p>Benutzer:\nme@xxx.net</p>\n<p>Passwort:\nxxx.</p>\n\n"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "<table bgcolor=\"green\" aaa=\"1\"><thead><tr><th colspan=\"2\" abc=\"a\">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>"
  should = "<table bgcolor=\"green\"><thead><tr><th colspan=\"2\">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>"
  result = App.Utils.htmlCleanup(source)
  equal(result.get(0).outerHTML, should, source)

  // strip out browser-inserted (broken) link (see https://github.com/zammad/zammad/issues/2019)
  source = "<div><a href=\"https://example.com/#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}\">test</a></div>"
  should = "<a href=\"#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}\">test</a>"
  result = App.Utils.htmlCleanup(source)
  equal(result.html(), should, source)

  source = "<table bgcolor=\"green\" aaa=\"1\" style=\"color: red\"><thead><tr style=\"margin-top: 10px\"><th colspan=\"2\" abc=\"a\" style=\"margin-top: 12px\">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>"
  should = "<table bgcolor=\"green\" style=\"color:red;\"><thead><tr style=\"margin-top:10px;\"><th colspan=\"2\" style=\"margin-top:12px;\">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>"
  result = App.Utils.htmlCleanup(source)
  result.get(0).outerHTML
  //equal(result.get(0).outerHTML, should, source) / string order is different on browsers
  equal(result.first().attr('bgcolor'), 'green')
  equal(result.first().attr('style'), 'color:red;')
  equal(result.first().attr('aaa'), undefined)
  equal(result.find('tr').first().attr('style'), 'margin-top:10px;')
  equal(result.find('th').first().attr('colspan'), '2')
  equal(result.find('th').first().attr('abc'), undefined)
  equal(result.find('th').first().attr('style'), 'margin-top:12px;')

  source = "<table bgcolor=\"green\" aaa=\"1\" style=\"color:red; display: none;\"><thead><tr><th colspan=\"2\" abc=\"a\">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>"
  should = "<table bgcolor=\"green\" style=\"color:red;\"><thead><tr><th colspan=\"2\">aaa</th></tr></thead><tbody><tr><td>value</td></tr></tbody></table>"
  result = App.Utils.htmlCleanup(source)
  //equal(result.get(0).outerHTML, should, source) / string order is different on browsers
  equal(result.first().attr('bgcolor'), 'green')
  equal(result.first().attr('style'), 'color:red;')
  equal(result.first().attr('aaa'), undefined)
  equal(result.find('tr').first().attr('style'), undefined)
  equal(result.find('th').first().attr('colspan'), '2')
  equal(result.find('th').first().attr('abc'), undefined)
  equal(result.find('th').first().attr('style'), undefined)

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
test("identify signature by plaintext", function() {

  var message = "<div>test 123 </div>"
  var should  = '<div>test 123 </div>'
  var result  = App.Utils.signatureIdentifyByPlaintext(message)
  equal(result, should)

  message = "<div>test 123 <br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message)
  equal(result, should)

  message = "<div>test 123 <br/>1<br/>2<br/>3<br/>4<br/>5<br/>6<br/>7<br/>8<br/>9<br/><br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/>1<br/>2<br/>3<br/>4<br/>5<br/>6<br/>7<br/>8<br/>9<br/><br/><span class="js-signatureMarker"></span>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><span class="js-signatureMarker"></span>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/> -- <br/>Bob Smith</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><span class="js-signatureMarker"></span> -- <br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--<br/>Bob Smith<br/><br/><br/><br/><br/>--<br/>Bob Smith</div>"
  should  = '<div>test 123 <br/><br/><span class="js-signatureMarker"></span>--<br/>Bob Smith<br/><br/><br/><br/><br/>--<br/>Bob Smith</div>'
  //should  = '<div>test 123 <br><br><br><br><br><br><br><br><br><br><br><span class="js-signatureMarker"></span>--<br>Bob Smith<br/><br/><br/><br/><br/>--<br/>Bob Smith</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123</div><div>test 123</div><div>--</div><div>Bob Smith</div>"
  should  = "<div>test 123</div><div>test 123</div><div><span class=\"js-signatureMarker\"></span>--</div><div>Bob Smith</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<p><span>test 123</span></p><p><span>test 123</span></p><p><span>--</span></p><p><span>Bob Smith</span></p><div></div>"
  should  = "<p><span>test 123</span></p><p><span>test 123</span></p><p><span><span class=\"js-signatureMarker\"></span>--</span></p><p><span>Bob Smith</span></p><div></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "Test reply to zammad<br><br>Am 24.10.2016 18:55 schrieb &quot;Android Support&quot; &lt;android-support@example.com&gt;:<br><br>&gt; <u></u><br>&gt; Sehr geehrte Damen"
  should  = "Test reply to zammad<br><br><span class=\"js-signatureMarker\"></span>Am 24.10.2016 18:55 schrieb &quot;Android Support&quot; &lt;android-support@example.com&gt;:<br><br>&gt; <u></u><br>&gt; Sehr geehrte Damen"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<br>&lt; On 20 Oct 2016, at 12:23, Martin Edenhofer via Zammad Helpdesk wrote:<br>"
  should = "<br><span class=\"js-signatureMarker\"></span>&lt; On 20 Oct 2016, at 12:23, Martin Edenhofer via Zammad Helpdesk wrote:<br>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // apple
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>On 01/04/15 10:55, Bob Smith wrote:<br/>lalala<p>--</p>some test</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>On 01/04/15 10:55, Bob Smith wrote:<br/>lalala<p>--</p>some test</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Am 03.04.2015 um 20:58 schrieb Bob Smith &lt;bob@example.com&gt;:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Am 03.04.2015 um 20:58 schrieb Bob Smith &lt;bob@example.com&gt;:<br/>lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // ms
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>Subject: lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>Subject: lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>1<br/>2<br/>3<br/>4<br/>4<br/>Subject: lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Sent: Donnerstag, 2. April 2015 10:00<br/>1<br/>2<br/>3<br/>4<br/>4<br/>Subject: lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Gesendet: Donnerstag, 2. April 2015 10:00<br/>Betreff: lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Von: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Gesendet: Donnerstag, 2. April 2015 10:00<br/>Betreff: lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div>"
  should  = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  should  = "<div>1<br><br></div><div><span class=\"js-signatureMarker\"></span>Von: Martin Edenhofer via Znuny Support [<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>]</div>\n<div>Gesendet: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>1<br><br></div><div>Von: Martin Edenhofer via Znuny Support &lt;<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>&gt;</div>\n<div>An: somebody</div><div>Datum: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  should  = "<div>1<br><br></div><div><span class=\"js-signatureMarker\"></span>Von: Martin Edenhofer via Znuny Support &lt;<a href=\"mailto:support@znuny.inc\" title=\"mailto:support@znuny.inc\" target=\"_blank\">mailto:support@znuny.inc</a>&gt;</div>\n<div>An: somebody</div><div>Datum: Donnerstag, 2. April 2015 11:32</div><div>Betreff: lalala</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>Von: &quot;Johannes Nickel via Znuny Projects&quot; &lt;<a href=\"mailto:projects@znuny.inc\" title=\"mailto:projects@znuny.inc\">projects@znuny.inc</a>&gt;</div><div>An: \"Lisa Smith\" &lt;<a href=\"mailto:lisa.smith@example.com\" title=\"mailto:lisa.smith@example.com\">lisa.smith@example.com</a>&gt;</div><div>Gesendet: Donnerstag, 2. April 2015 10:11:12</div><div>Betreff: Angebot Redundanz / Paket mit Silver Subscription [Ticket#424242]</div><div><br></div><div>Hallo Frau Smith,</div>"
  should  = "<div><span class=\"js-signatureMarker\"></span>Von: &quot;Johannes Nickel via Znuny Projects&quot; &lt;<a href=\"mailto:projects@znuny.inc\" title=\"mailto:projects@znuny.inc\">projects@znuny.inc</a>&gt;</div><div>An: \"Lisa Smith\" &lt;<a href=\"mailto:lisa.smith@example.com\" title=\"mailto:lisa.smith@example.com\">lisa.smith@example.com</a>&gt;</div><div>Gesendet: Donnerstag, 2. April 2015 10:11:12</div><div>Betreff: Angebot Redundanz / Paket mit Silver Subscription [Ticket#424242]</div><div><br></div><div>Hallo Frau Smith,</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>Hi Johannes,</div><div><br></div><div>das Angebot für den halben Tag bitte an uns.</div><div>Der Termin hat sich jetzt auf 10-12 Uhr verschoben, hab ich dir weitergeleitet.</div><div><br></div><div>Viele Grüße</div><div>Max</div><div><br></div><div>&gt; On 07 Oct 2015, at 11:55, Johannes Smith &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>smith@example.com</a> &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>mailto:smith@example.com</a>&gt;&gt; wrote:</div><div>&gt;</div><div>&gt; Hi,</div><div>&gt;</div><div>&gt; OK. Wer kriegt das Angebot? Ist das wirklich nur ein halber Tag?</div></div>"
  should  = "<div>Hi Johannes,</div><div><br></div><div>das Angebot für den halben Tag bitte an uns.</div><div>Der Termin hat sich jetzt auf 10-12 Uhr verschoben, hab ich dir weitergeleitet.</div><div><br></div><div>Viele Grüße</div><div>Max</div><div><br></div><div><span class=\"js-signatureMarker\"></span>&gt; On 07 Oct 2015, at 11:55, Johannes Smith &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>smith@example.com</a> &lt;<a href=mailto:smith@example.com title=mailto:smith@example.com target=_blank>mailto:smith@example.com</a>&gt;&gt; wrote:</div><div>&gt;</div><div>&gt; Hi,</div><div>&gt;</div><div>&gt; OK. Wer kriegt das Angebot? Ist das wirklich nur ein halber Tag?</div></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "Dear Mr. Smith,<div><br></div><div>it seems to be, dass Sie den AutoIncrement Nummerngenerator für Ihre ITSMChangeManagement Installation verwenden. Seit ABC 3.2 wird führend vor der sich in der Datei&nbsp;<span style=\"line-height: 1.45; background-color: initial;\">&lt;ABC_CONFIG_Home&gt;/war/log/ITSMChangeCounter.log &nbsp;befindenden Zahl die SystemID (SysConfig) geschrieben. Dies ist ein Standardverhalten, dass auch bei der Ticketnummer verwendet wird.<br><br>Please ask me if you have questions.</span></div><div><span style=\"line-height: 1.45; background-color: initial;\"><br></span></div><div><span style=\"line-height: 1.45; background-color: initial;\">Viele Grüße,</span></div><div><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n<br>Enterprise Services for ABC\n<br>\n<br>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany\n<br>\n<br>P: +49 (0) 30 111 111 111-0\n<br>F: +49 (0) 30 111 111 111-8\n<br>W: http://znuny.com \n<br>\n<br>Location: Berlin - HRB 12345678 B Amtsgericht Berlin-Charlottenburg\n<br>Managing Director: Martin Edenhofer\n<br></div></div>"
  should  = "Dear Mr. Smith,<div><br></div><div>it seems to be, dass Sie den AutoIncrement Nummerngenerator für Ihre ITSMChangeManagement Installation verwenden. Seit ABC 3.2 wird führend vor der sich in der Datei&nbsp;<span style=\"line-height: 1.45; background-color: initial;\">&lt;ABC_CONFIG_Home&gt;/war/log/ITSMChangeCounter.log &nbsp;befindenden Zahl die SystemID (SysConfig) geschrieben. Dies ist ein Standardverhalten, dass auch bei der Ticketnummer verwendet wird.<br><br>Please ask me if you have questions.</span></div><div><span style=\"line-height: 1.45; background-color: initial;\"><br></span></div><div><span style=\"line-height: 1.45; background-color: initial;\">Viele Grüße,</span></div><div><span class=\"js-signatureMarker\"></span><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n<br>Enterprise Services for ABC\n<br>\n<br>Znuny GmbH // Marienstraße 11 // 10117 Berlin // Germany\n<br>\n<br>P: +49 (0) 30 111 111 111-0\n<br>F: +49 (0) 30 111 111 111-8\n<br>W: http://znuny.com \n<br>\n<br>Location: Berlin - HRB 12345678 B Amtsgericht Berlin-Charlottenburg\n<br>Managing Director: Martin Edenhofer\n<br></div></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true, true)
  equal(result, should)

  message = "Dear Mr. Smith, nice to read you,<div><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  should  = "Dear Mr. Smith, nice to read you,<div><span class=\"js-signatureMarker\"></span><div data-signature=\"true\" data-signature-id=\"1\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true, true)
  equal(result, should)

  message = "Dear Mr. Smith, nice to read you,<div><div data-signature=\"true\" data-signature-id=\"9999\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  should  = "Dear Mr. Smith, nice to read you,<div><div data-signature=\"true\" data-signature-id=\"9999\">&nbsp; Thorsten Smith\n<br>\n<br>--\n</div></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, false, true)
  equal(result, should)

  // fr
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Envoyé : mercredi 29 avril 2015 17:31<br/>Objet : lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>De : Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]<br/>Envoyé : mercredi 29 avril 2015 17:31<br/>Objet : lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // thunderbird
  // de
  message = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div>Am 04.03.2015 um 12:47 schrieb Martin Edenhofer via Znuny Sales:</div><div>&gt; Hallo Christian,</div>"
  should  = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div><span class=\"js-signatureMarker\"></span>Am 04.03.2015 um 12:47 schrieb Martin Edenhofer via Znuny Sales:</div><div>&gt; Hallo Christian,</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // en - Thunderbird default - http://kb.mozillazine.org/Reply_header_settings
  message = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div>On 01-01-2007 11:00 AM, Alf Aardvark wrote:</div><div>&gt; Hallo Christian,</div>"
  should  = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div><span class=\"js-signatureMarker\"></span>On 01-01-2007 11:00 AM, Alf Aardvark wrote:</div><div>&gt; Hallo Christian,</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // en - http://kb.mozillazine.org/Reply_header_settings
  message = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div>Alf Aardvark wrote, on 01-01-2007 11:00 AM:</div><div>&gt; Hallo Christian,</div>"
  should  = "<div><br></div><div>Viele Grüße,</div><div>Christian</div><div><br></div><div><span class=\"js-signatureMarker\"></span>Alf Aardvark wrote, on 01-01-2007 11:00 AM:</div><div>&gt; Hallo Christian,</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // otrs
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>01/04/15 10:55 - Bob Smith wrote:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>01/04/15 10:55 - Bob Smith wrote:<br/>lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>01/04/15 10:55 - Bob Smith schrieb:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>01/04/15 10:55 - Bob Smith schrieb:<br/>lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/></div><div>24.02.2015 14:20 - Roy Kaldung via Znuny Sales schrieb: &nbsp;</div>"
  should  = "<div>test 123 <br/><br/></div><div><span class=\"js-signatureMarker\"></span>24.02.2015 14:20 - Roy Kaldung via Znuny Sales schrieb: &nbsp;</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // zammad
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><div data-signature=\"true\" data-signature-id=\"5\">lalala</div></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><div data-signature=\"true\" data-signature-id=\"5\">lalala</div></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><blockquote type=\"cite\">lalala</blockquote></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><blockquote type=\"cite\">lalala</blockquote></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // gmail
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><blockquote class=\"ecxgmail_quote\">lalala</blockquote></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><blockquote class=\"ecxgmail_quote\">lalala</blockquote></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><blockquote class=\"gmail_quote\">lalala</blockquote></div>"
  should  = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span><blockquote class=\"gmail_quote\">lalala</blockquote></div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Am 24. Dezember 2015 um 07:45 schrieb kathrine &lt;kathrine@example.com&gt;:<br/>lalala</div>"
  should = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class=\"js-signatureMarker\"></span>Am 24. Dezember 2015 um 07:45 schrieb kathrine &lt;kathrine@example.com&gt;:<br/>lalala</div>"
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // word 14
  // en
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Bob Smith wrote:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Bob Smith wrote:<br/>lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

  // de
  message = "<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/>Bob Smith schrieb:<br/>lalala</div>"
  should  = '<div>test 123 <br/><br/>--no not match--<br/><br/>Bob Smith<br/><span class="js-signatureMarker"></span>Bob Smith schrieb:<br/>lalala</div>'
  result  = App.Utils.signatureIdentifyByPlaintext(message, true)
  equal(result, should)

});


test("identify signature by HTML", function() {

  var message = "<div>test 123 </div>"
  var should  = message
  var result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)


  // test if, according to jQuery, invalid HTML does not cause a a crash
  // https://github.com/zammad/zammad/issues/3393
  message = "<td></td><table></table><div>test 123 </div>"
  should  = message
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // simple case 1
  message = '<div>actual content</div><blockquote>quoted content</blockquote>'
  should  = '<div>actual content</div><span class="js-signatureMarker"></span><blockquote>quoted content</blockquote>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // simple case 2
  message = '<div>actual content</div><blockquote>quoted content</blockquote><br><div><br></div><div><br>   </div>'
  should  = '<div>actual content</div><span class="js-signatureMarker"></span><blockquote>quoted content</blockquote><br><div><br></div><div><br>   </div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // simple case 3
  message = '<div>actual content</div><blockquote>quoted content</blockquote><br><div>actual content 2</div>'
  should  = message
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // simple case 4
  message = '  content 0  <div>content 1</div> content 2  <blockquote>quoted content</blockquote><br><div><br></div><div><br>   </div>'
  should  = '  content 0  <div>content 1</div> content 2  <span class="js-signatureMarker"></span><blockquote>quoted content</blockquote><br><div><br></div><div><br>   </div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // ignore mail structures of case Ticket#1085048
  message = '<div><span style="color:#9c6500;">CAUTION:</span> This email originated from outside of the organization. Do not click links or open attachments unless you recognize the sender and know the content is safe.</div><br><div><p>actual content</p><div><p>actual content 2</p></div><p>&nbsp;</p><div><p>actual quote</p></div><div><blockquote><p>actual quote</p></blockquote></div><div><p>&nbsp;</p></div><p>&nbsp;</p></div></div>'
  should  = '<div><span style="color:#9c6500;">CAUTION:</span> This email originated from outside of the organization. Do not click links or open attachments unless you recognize the sender and know the content is safe.</div><br><div><p>actual content</p><div><p>actual content 2</p></div><p>&nbsp;</p><div><p>actual quote</p></div><div><blockquote><p>actual quote</p></blockquote></div><div><p>&nbsp;</p></div><p>&nbsp;</p></div></div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Gmail via Safari on MacOS 10.12
  message = '<div dir="ltr">Reply with <b>gmail</b> via Safari on MacOS 10.12</div><br>\
    <div>\
    <div dir="ltr">Am Mi., 5. Sep. 2018 um 09:22 Uhr schrieb Billy Zhou &lt;bz@zammad.com&gt;:<br>\
    </div>\
    <blockquote>test email content<br>\
    <br>\
    </blockquote>\
    </div>'
  should = '<div dir="ltr">Reply with <b>gmail</b> via Safari on MacOS 10.12</div><br>\
    <span class=\"js-signatureMarker\"></span><div>\
    <div dir="ltr">Am Mi., 5. Sep. 2018 um 09:22 Uhr schrieb Billy Zhou &lt;bz@zammad.com&gt;:<br>\
    </div>\
    <blockquote>test email content<br>\
    <br>\
    </blockquote>\
    </div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Yahoo Mail via Safari on MacOS 10.12
  message = '<div style="color:#000; background-color:#fff; font-family:Helvetica Neue, Helvetica, Arial, Lucida Grande, sans-serif;font-size:16px"><div id="yui_3_16_0_ym19_1_1536132243868_2594"><span id="yui_3_16_0_ym19_1_1536132243868_2593">Reply with <b id="yui_3_16_0_ym19_1_1536132243868_2597">Yahoo Mail</b> via Safari on MacOS 10.12</span></div> <div class="qtdSeparateBR"><br><br></div><div class="yahoo_quoted" style="display: block;"> <div style="font-family: Helvetica Neue, Helvetica, Arial, Lucida Grande, sans-serif; font-size: 16px;"> <div style="font-family: HelveticaNeue, Helvetica Neue, Helvetica, Arial, Lucida Grande, sans-serif; font-size: 16px;"> <div dir="ltr"><font size="2" face="Arial"> Billy Zhou &lt;bz@zammad.com&gt; schrieb am 9:08 Mittwoch, 5.September 2018:<br></font></div>  <br><br> <div class="y_msg_container"><div dir="ltr">test email content<br></div><div dir="ltr"><br></div><br><br></div>  </div> </div>  </div></div>'
  should  = '<div style="color:#000; background-color:#fff; font-family:Helvetica Neue, Helvetica, Arial, Lucida Grande, sans-serif;font-size:16px"><div id="yui_3_16_0_ym19_1_1536132243868_2594"><span id="yui_3_16_0_ym19_1_1536132243868_2593">Reply with <b id="yui_3_16_0_ym19_1_1536132243868_2597">Yahoo Mail</b> via Safari on MacOS 10.12</span></div> <div class="qtdSeparateBR"><br><br></div><span class="js-signatureMarker"></span><div class="yahoo_quoted" style="display: block;"> <div style="font-family: Helvetica Neue, Helvetica, Arial, Lucida Grande, sans-serif; font-size: 16px;"> <div style="font-family: HelveticaNeue, Helvetica Neue, Helvetica, Arial, Lucida Grande, sans-serif; font-size: 16px;"> <div dir="ltr"><font size="2" face="Arial"> Billy Zhou &lt;bz@zammad.com&gt; schrieb am 9:08 Mittwoch, 5.September 2018:<br></font></div>  <br><br> <div class="y_msg_container"><div dir="ltr">test email content<br></div><div dir="ltr"><br></div><br><br></div>  </div> </div>  </div></div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Thunderbird 52 on MacOS 10.12
  message = 'Reply with <b>Thunderbird 52</b> on MacOS 10.12<br>\
    <br>\
    <div class="moz-cite-prefix">Am 04.09.18 um 15:32 schrieb Billy\
      Zhou:<br>\
    </div>\
    <blockquote type="cite"\
      cite="mid:da18ed01-b187-a383-bfe7-72663cf82a83@zammad.com">test\
      email content\
      <br>\
      <br>\
    </blockquote>\
    <br>'
  should = 'Reply with <b>Thunderbird 52</b> on MacOS 10.12<br>\
    <br>\
    <div class="moz-cite-prefix">Am 04.09.18 um 15:32 schrieb Billy\
      Zhou:<br>\
    </div>\
    <span class=\"js-signatureMarker\"></span><blockquote type="cite" cite="mid:da18ed01-b187-a383-bfe7-72663cf82a83@zammad.com">test\
      email content\
      <br>\
      <br>\
    </blockquote>\
    <br>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Apple Mail on MacOS 10
  message = '<div class="">Reply by <b class="">Apple Mail</b> on MacOS 10.</div><div class=""><br class=""></div><br class=""><div><blockquote type="cite" class=""><div class="">On 4. Sep 2018, at 15:32, Billy Zhou &lt;<a href="mailto:bz@zammad.com" class="">bz@zammad.com</a>&gt; wrote:</div><br class="Apple-interchange-newline"><div class=""><div class="">test email content<br class=""><br class=""></div></div></blockquote></div><br class="">'
  should  = '<div class="">Reply by <b class="">Apple Mail</b> on MacOS 10.</div><div class=""><br class=""></div><br class=""><span class=\"js-signatureMarker\"></span><div><blockquote type="cite" class=""><div class="">On 4. Sep 2018, at 15:32, Billy Zhou &lt;<a href="mailto:bz@zammad.com" class="">bz@zammad.com</a>&gt; wrote:</div><br class="Apple-interchange-newline"><div class=""><div class="">test email content<br class=""><br class=""></div></div></blockquote></div><br class="">'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Office 365 (10325.20118) on Windows 10 Build 1803
  // With German marker: -----Ursprüngliche Nachricht-----
  // Using fallback to signatureIdentifyByPlaintext
  message = '<div>\
<p>Reply with Office 365 (10325.20118) on Windows 10 Build 1803</p>\
<p> </p>\
<p><b>fett</b></p>\
<p> </p>\
<span class="js-signatureMarker"></span><p>--</p>\
<p>Zammad GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>\
<p> </p>\
<p>P: +49 (0) 30 55 57 160-0</p>\
<p>F: +49 (0) 30 55 57 160-99</p>\
<p>W: <a href="https://zammad.com" rel="nofollow noreferrer noopener" target="_blank">https://zammad.com</a></p>\
<p> </p>\
<p>Location: Berlin - HRB 163946 B Amtsgericht Berlin-Charlottenburg</p>\
<p>Managing Director: Martin Edenhofer</p>\
<p> </p>\
<p>-----Ursprüngliche Nachricht-----<br>Von: Billy Zhou &lt;bz@zammad.com&gt; <br>Gesendet: Dienstag, 4. September 2018 15:33<br>An: me@zammad.com<br>Betreff: test email title</p>\
<p> </p>\
<p>test email content</p>\
<p> </p>\
</div>'
  should = '<div>\
<p>Reply with Office 365 (10325.20118) on Windows 10 Build 1803</p>\
<p> </p>\
<p><b>fett</b></p>\
<p> </p>\
<span class="js-signatureMarker"></span><p><span class=\"js-signatureMarker\"></span>--</p>\
<p>Zammad GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>\
<p> </p>\
<p>P: +49 (0) 30 55 57 160-0</p>\
<p>F: +49 (0) 30 55 57 160-99</p>\
<p>W: <a href="https://zammad.com" rel="nofollow noreferrer noopener" target="_blank">https://zammad.com</a></p>\
<p> </p>\
<p>Location: Berlin - HRB 163946 B Amtsgericht Berlin-Charlottenburg</p>\
<p>Managing Director: Martin Edenhofer</p>\
<p> </p>\
<p>-----Ursprüngliche Nachricht-----<br>Von: Billy Zhou &lt;bz@zammad.com&gt; <br>Gesendet: Dienstag, 4. September 2018 15:33<br>An: me@zammad.com<br>Betreff: test email title</p>\
<p> </p>\
<p>test email content</p>\
<p> </p>\
</div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Office 365 (10325.20118) on Windows 10 Build 1803
  // With English marker: -----Original Message-----
  // Using fallback to signatureIdentifyByPlaintext
  message = '<div>\
<p>Reply with Office 365 (10325.20118) on Windows 10 Build 1803</p>\
<p> </p>\
<p><b>fett</b></p>\
<p> </p>\
<span class="js-signatureMarker"></span><p>--</p>\
<p>Zammad GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>\
<p> </p>\
<p>P: +49 (0) 30 55 57 160-0</p>\
<p>F: +49 (0) 30 55 57 160-99</p>\
<p>W: <a href="https://zammad.com" rel="nofollow noreferrer noopener" target="_blank">https://zammad.com</a></p>\
<p> </p>\
<p>Location: Berlin - HRB 163946 B Amtsgericht Berlin-Charlottenburg</p>\
<p>Managing Director: Martin Edenhofer</p>\
<p> </p>\
<p>-----Original Message-----<br>Von: Billy Zhou &lt;bz@zammad.com&gt; <br>Gesendet: Dienstag, 4. September 2018 15:33<br>An: me@zammad.com<br>Betreff: test email title</p>\
<p> </p>\
<p>test email content</p>\
<p> </p>\
</div>'
  should = '<div>\
<p>Reply with Office 365 (10325.20118) on Windows 10 Build 1803</p>\
<p> </p>\
<p><b>fett</b></p>\
<p> </p>\
<span class="js-signatureMarker"></span><p><span class=\"js-signatureMarker\"></span>--</p>\
<p>Zammad GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>\
<p> </p>\
<p>P: +49 (0) 30 55 57 160-0</p>\
<p>F: +49 (0) 30 55 57 160-99</p>\
<p>W: <a href="https://zammad.com" rel="nofollow noreferrer noopener" target="_blank">https://zammad.com</a></p>\
<p> </p>\
<p>Location: Berlin - HRB 163946 B Amtsgericht Berlin-Charlottenburg</p>\
<p>Managing Director: Martin Edenhofer</p>\
<p> </p>\
<p>-----Original Message-----<br>Von: Billy Zhou &lt;bz@zammad.com&gt; <br>Gesendet: Dienstag, 4. September 2018 15:33<br>An: me@zammad.com<br>Betreff: test email title</p>\
<p> </p>\
<p>test email content</p>\
<p> </p>\
</div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)

  // Office 365 (10325.20118) on Windows 10 Build 1803
  // With German marker: -----Ursprüngliche Nachricht-----
  // Without any existing <span class="js-signatureMarker"></span>
  // Using fallback to signatureIdentifyByPlaintext
  message = '<div>\
<p>Reply with Office 365 (10325.20118) on Windows 10 Build 1803</p>\
<p> </p>\
<p><b>fett</b></p>\
<p> </p>\
<p>--</p>\
<p>Zammad GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>\
<p> </p>\
<p>P: +49 (0) 30 55 57 160-0</p>\
<p>F: +49 (0) 30 55 57 160-99</p>\
<p>W: <a href="https://zammad.com" rel="nofollow noreferrer noopener" target="_blank">https://zammad.com</a></p>\
<p> </p>\
<p>Location: Berlin - HRB 163946 B Amtsgericht Berlin-Charlottenburg</p>\
<p>Managing Director: Martin Edenhofer</p>\
<p> </p>\
<p>-----Ursprüngliche Nachricht-----<br>Von: Billy Zhou &lt;bz@zammad.com&gt; <br>Gesendet: Dienstag, 4. September 2018 15:33<br>An: me@zammad.com<br>Betreff: test email title</p>\
<p> </p>\
<p>test email content</p>\
<p> </p>\
</div>'
  should = '<div>\
<p>Reply with Office 365 (10325.20118) on Windows 10 Build 1803</p>\
<p> </p>\
<p><b>fett</b></p>\
<p> </p>\
<p><span class=\"js-signatureMarker\"></span>--</p>\
<p>Zammad GmbH // Marienstraße 11 // 10117 Berlin // Germany</p>\
<p> </p>\
<p>P: +49 (0) 30 55 57 160-0</p>\
<p>F: +49 (0) 30 55 57 160-99</p>\
<p>W: <a href="https://zammad.com" rel="nofollow noreferrer noopener" target="_blank">https://zammad.com</a></p>\
<p> </p>\
<p>Location: Berlin - HRB 163946 B Amtsgericht Berlin-Charlottenburg</p>\
<p>Managing Director: Martin Edenhofer</p>\
<p> </p>\
<p>-----Ursprüngliche Nachricht-----<br>Von: Billy Zhou &lt;bz@zammad.com&gt; <br>Gesendet: Dienstag, 4. September 2018 15:33<br>An: me@zammad.com<br>Betreff: test email title</p>\
<p> </p>\
<p>test email content</p>\
<p> </p>\
</div>'
  result  = App.Utils.signatureIdentifyByHtml(message)
  equal(result, should)
});

// check attachment references
test("check check attachment reference", function() {
  var message = 'some not existing'
  var result = false
  var verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = 'some attachment for you'
  result = 'Attachment'
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = 'your attachment.'
  result = 'Attachment'
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = 'some otherattachment for you'
  result = false
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = 'some attachmentother for you'
  result = false
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = 'someattachment'
  result = false
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = 'As enclosed you will find.'
  result = 'Enclosed'
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = '<div>Hi Test,</div><div><blockquote>On Monday, 22 July 2019, 14:07:54, Test User wrote:<br><br>Test attachment <br></blockquote></div>'
  result = false
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = '<div>Hi Test,</div><div><blockquote type="cite">cite attachment </blockquote></div>'
  result = false
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)

  message = '<div>Hi Test,</div><div><blockquote class="ecxgmail_quote">ecxgmail_quote attachment </blockquote></div>'
  result = false
  verify = App.Utils.checkAttachmentReference(message)
  equal(verify, result)
});

// replace tags
test("check replace tags", function() {
  var formatNumber = function(num, digits) {
    while (num.toString().length < digits) {
      num = '0' + num
    }
    return num
  }
  var formatTimestamp = function(timestamp) {
    localTime = new Date(Date.parse(timestamp))
    d         = formatNumber(localTime.getDate(), 2)
    m         = formatNumber(localTime.getMonth() + 1, 2)
    yfull     = localTime.getFullYear()
    M         = formatNumber(localTime.getMinutes(), 2)
    H         = formatNumber(localTime.getHours(), 2)
    return m + '/' + d + '/' + yfull + ' ' + H + ':' + M
  }

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
  result  = '<div>Bob -</div>'
  data    = {
    user: {
      firstname: 'Bob',
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.lastname}</div>"
  result  = '<div>Bob 0</div>'
  data    = {
    user: {
      firstname: 'Bob',
      lastname: 0,
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.lastname}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: {
      firstname: 'Bob',
      lastname: '',
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.not.existing.test}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: {
      firstname: 'Bob',
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{not.existing.test}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: {
      firstname: 'Bob',
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{not.existing.test}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: {
      firstname: 'Bob',
      not: null,
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{not.existing.test}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: {
      firstname: 'Bob',
      not: {},
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{<a href=\"/test\">user.lastname</a>}</div>"
  result  = '<div>Bob Smith</div>'
  data    = {
    user: {
      firstname: 'Bob',
      lastname: 'Smith',
    },
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  user = new App.User({
    firstname: 'Bob',
    lastname: 'Smith Good',
    created_at: '2018-10-31T10:00:00Z',
  })
  message = "<div>#{user.firstname} #{user.created_at}</div>"
  result  = '<div>Bob ' + formatTimestamp('2018-10-31T10:00:00Z') + '</div>'
  data    = {
    user: user
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.created_at.date}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: user
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<div>#{user.firstname} #{user.created.date}</div>"
  result  = '<div>Bob -</div>'
  data    = {
    user: user
  }
  verify = App.Utils.replaceTags(message, data)
  equal(verify, result)

  message = "<a href=\"https://example.co/q=#{user.lastname}\">some text</a>"
  result  = '<a href=\"https://example.co/q=Smith%20Good\">some text</a>'
  data    = {
    user: user
  }
  verify = App.Utils.replaceTags(message, data, true)
  equal(verify, result)
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
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff')


  dataNow = {
    owner_id:  '',
    state_ids: [1,5,6,7],
  }
  dataLast = {}
  diff = {
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


  // regression test for issue #2042 - incorrect notification when closing a tab after setting up an object
  // A newly created attribute will have the empty string as its value, this should be ignored for formDiff comparison
  dataNow = {
    test: '',
  }
  dataLast = {}
  diff = {}
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff for a newly created attribute that is blank')


  dataNow = {
    test: '',
  }
  dataLast = {
    test: '123',
  }
  diff = {
    test: '',
  }
  result = App.Utils.formDiff(dataNow, dataLast)
  deepEqual(result, diff, 'check form diff for setting a previously valid value to blank')


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

// check diffPosition
test("check diffPosition format", function() {

  var a = [1,2,3,4]
  var b = [1,2,3,4,5]
  var result = [
    {
      position: 4,
      id: 5,
    },
  ]
  var verify = App.Utils.diffPositionAdd(a, b)
  deepEqual(verify, result)

  a = [2,3,4]
  b = [1,2,3,4]
  result = [
    {
      position: 0,
      id: 1,
    },
  ]
  verify = App.Utils.diffPositionAdd(a, b)
  deepEqual(verify, result)

  a = [2,3,4]
  b = [1,2,3,4,5]
  result = [
    {
      position: 0,
      id: 1,
    },
    {
      position: 4,
      id: 5,
    },
  ]
  verify = App.Utils.diffPositionAdd(a, b)
  deepEqual(verify, result)

  a = [2,3,4]
  b = [1,99,12,2,3,4,5]
  result = [
    {
      position: 0,
      id: 1,
    },
    {
      position: 1,
      id: 99,
    },
    {
      position: 2,
      id: 12,
    },
    {
      position: 6,
      id: 5,
    },
  ]
  verify = App.Utils.diffPositionAdd(a, b)
  deepEqual(verify, result)

  a = [4,3,1]
  b = [1,2,3,4,5]
  result = false
  verify = App.Utils.diffPositionAdd(a, b)
  deepEqual(verify, result)

  a = ['Ticket-347', 'TicketCreateScreen-2217']
  b = ['Ticket-347', 'TicketCreateScreen-2217', 'TicketCreateScreen-71517']
  result = [
    {
      position: 2,
      id: 'TicketCreateScreen-71517',
    },
  ]
  verify = App.Utils.diffPositionAdd(a, b)
  deepEqual(verify, result)

});

// check textLengthWithUrl format
test("check textLengthWithUrl format", function() {

  var string = '123'
  var result = 3
  var verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = '123 http is not here'
  result = 20
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = '123 http://host is not here'
  result = 39
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = '123 http://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX is not here'
  result = 39
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = 'http://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  result = 23
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = 'http://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX, some other text'
  result = 23 + 17
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = 'some other text,http://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
  result = 23 + 16
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

  string = 'some other text, http://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX?abc=123;aaa=ab+c usw'
  result = 23 + 21
  verify = App.Utils.textLengthWithUrl(string)
  equal(verify, result)

});

// check getRecipientArticle format
test('check getRecipientArticle format', function() {

  var customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  var ticket = {
    customer: customer,
  }
  var article = {
    type: {
      name: 'phone',
    },
    sender: {
      name: 'Customer',
    },
    from: customer.email,
    to: 'some group',
    message_id: 'message_id1',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    },
  }
  var result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id1',
  }
  var verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    type: {
      name: 'phone',
    },
    sender: {
      name: 'Customer',
    },
    from: customer.email,
    message_id: 'message_id2',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    },
  }
  result = {
    to:          customer.email,
    cc:          '',
    body:        '',
    in_reply_to: 'message_id2',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id3',
    type: {
      name: 'phone',
    },
    sender: {
      name: 'Agent',
    },
    from: 'article_created_by@example.com',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    },
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id3',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id4',
    created_by: customer,
    type: {
      name: 'web',
    },
    sender: {
      name: 'Customer',
    },
    from: customer.email,
    to: 'some group',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    },
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id4',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id5',
    type: {
      name: 'web',
    },
    sender: {
      name: 'Customer',
    },
    from: customer.email,
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    }
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id5',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id6',
    type: {
      name: 'email',
    },
    sender: {
      name: 'Customer',
    },
    from: customer.email,
    to: 'some group',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    }
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id6',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id7',
    type: {
      name: 'email',
    },
    sender: {
      name: 'Customer',
    },
    from: 'some other invalid part, ' + customer.email,
    to: 'some group',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    }
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id7',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  console.log(verify)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id7.1',
    type: {
      name: 'email',
    },
    sender: {
      name: 'Customer',
    },
    from: 'some other invalid part, Some Realname ' + customer.email,
    to: 'some group',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    }
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id7.1',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  console.log(verify)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id7.2',
    type: {
      name: 'email',
    },
    sender: {
      name: 'Customer',
    },
    from: 'some other invalid part, Some Realname ' + customer.email + ' , abc',
    to: 'some group',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    }
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id7.2',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  console.log(verify)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id8',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'customer2@example.com',
    to: 'customer@example.com',
  }
  result = {
    to:          'customer2@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id8',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id9',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'agent@example.com',
    to: 'customer@example.com',
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id9',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id10',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent@Example.com',
    to: 'customer@example.com',
    cc: 'zammad@example.com',
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id10',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id11',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent@Example.com',
    to: 'customer@example.com, agent@example.com',
    cc: 'zammad@example.com',
  }
  result = {
    to:          'customer@example.com, agent@example.com',
    cc:          'zammad@example.com',
    body:        '',
    in_reply_to: 'message_id11',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type, [], true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id12',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent@Example.com',
    to: 'customeR@EXAMPLE.com, agent@example.com',
    cc: 'zammad@example.com, customer@example.com',
  }
  result = {
    to:          'customer@example.com, agent@example.com',
    cc:          'zammad@example.com',
    body:        '',
    in_reply_to: 'message_id12',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, [], true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id13',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent@Example.com',
    to: 'customeR@EXAMPLE.com, agent@example.com, zammad2@EXAMPLE.com',
    cc: 'zammad@example.com, customer2@example.com',
  }
  result = {
    to:          'customer@example.com, agent@example.com',
    cc:          'customer2@example.com',
    body:        '',
    in_reply_to: 'message_id13',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'AGENT@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id14',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent@Example.com',
    to: 'customeR@EXAMPLE.com, agent@example.com, zammad2@EXAMPLE.com',
    cc: 'zammad@example.com, customer2@example.com',
  }
  result = {
    to:          'customer@example.com, agent@example.com',
    cc:          'customer2@example.com',
    body:        '',
    in_reply_to: 'message_id14',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'zammad@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id15',
    created_by: customer,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'zammad@EXAMPLE.com',
    to: 'customeR@EXAMPLE.com, agent@example.com, zammad2@EXAMPLE.com',
    cc: 'zammad@example.com, customer2@example.com',
  }
  result = {
    to:          'customer@example.com, agent@example.com',
    cc:          'customer2@example.com',
    body:        '',
    in_reply_to: 'message_id15',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id16',
    created_by: customer,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'customer@example.com',
    to: 'customer1@example.com, customer2@example.com, zammad@example.com',
    cc: '',
  }
  result = {
    to:          'customer1@example.com, customer2@example.com, customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id16',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id17',
    created_by: customer,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'customer@example.com',
    to: 'customer1@example.com, customer2@example.com, zammad@example.com, customer2+2@example.com',
    cc: '',
  }
  result = {
    to:          'customer1@example.com, customer2@example.com, customer2+2@example.com, customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id17',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'zammad@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id18',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'zammad@example.com',
    to: 'customer@example.com',
    cc: '',
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id18',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, true)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'customer@example.com',
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'zammad@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id19',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Sender <zammad@example.com>',
    to: 'Customer <customer@example.com>',
    cc: '',
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id19',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, false)
  deepEqual(verify, result)

  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: agent,
  }
  article = {
    message_id: 'message_id20',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent <Agent@Example.com>',
    to: 'Sender <zammad@example.com>',
    cc: '',
  }
  result = {
    to:          'agent@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id20',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, false)
  deepEqual(verify, result)

  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: agent,
  }
  article = {
    message_id: 'message_id20',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: 'Agent <Agent@Example.com>',
    to: 'somebodyelse@example.com, Zammad <zammad@example.com>',
    cc: '',
  }
  result = {
    to:          'agent@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id20',
  }
  email_addresses = [
    {
      email: 'zammad@example.com',
    },
    {
      email: 'zammad2@example.com',
    }
  ]
  verify = App.Utils.getRecipientArticle(ticket, article, agent, article.type, email_addresses, false)
  deepEqual(verify, result)

  customer = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: "'customer@example.com'",
  }
  agent = {
    login: 'login',
    firstname: 'firstname',
    lastname: 'lastname',
    email: 'agent@example.com',
  }
  ticket = {
    customer: customer,
  }
  article = {
    message_id: 'message_id21',
    created_by: agent,
    type: {
      name: 'email',
    },
    sender: {
      name: 'Agent',
    },
    from: customer.email,
    to: 'agent@example.com',
  }
  result = {
    to:          'customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id21',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  // Regression test for issue #2184
  // Case 1
  // 1. Create a "Received Call" Ticket for article_customer
  // 2. Change the Customer of the ticket to ticket_customer (but article.from still points to article_customer)
  // 3. Reply to the first Article
  // Recipient SHOULD BE Article.from

  var article_customer = {
    login: 'login',
    firstname: 'article',
    lastname: 'lastname',
    email: 'article_customer@example.com',
  }
  var ticket_customer = {
    login: 'login2',
    firstname: 'ticket',
    lastname: 'lastname',
    email: 'ticket_customer@example.com',
  }
  ticket = {
    customer: ticket_customer,
  }
  article = {
    type: {
      name: 'phone',
    },
    sender: {
      name: 'Customer',
    },
    from: 'article lastname <article_customer@example.com>',
    to: 'some group',
    message_id: 'message_id22',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    },
  }
  result = {
    to:          'article_customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id22',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

  // Regression test for issue #2184
  // Case 2
  // 1. Create a "Outbound Call" Ticket for article_customer
  // 2. Change the Customer of the Ticket to ticket_customer (but article.to still points to article_customer)
  // 3. Reply to the first Article
  // Recipient SHOULD BE Article.to

  article_customer = {
    login: 'login',
    firstname: 'article',
    lastname: 'lastname',
    email: 'article_customer@example.com',
  }
  ticket_customer = {
    login: 'login2',
    firstname: 'ticket',
    lastname: 'lastname',
    email: 'ticket_customer@example.com',
  }
  ticket = {
    customer: ticket_customer,
  }
  article = {
    type: {
      name: 'phone',
    },
    sender: {
      name: 'Agent',
    },
    from: 'agent1@example.com',
    to: article_customer.email,
    message_id: 'message_id23',
    created_by: {
      login: 'login',
      firstname: 'firstname',
      lastname: 'lastname',
      email: 'article_created_by@example.com',
    },
  }
  result = {
    to:          'article_customer@example.com',
    cc:          '',
    body:        '',
    in_reply_to: 'message_id23',
  }
  verify = App.Utils.getRecipientArticle(ticket, article, article.created_by, article.type)
  deepEqual(verify, result)

});

test("contentTypeCleanup", function() {

  var source = "image/png"
  var should = "image/png"
  var result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)

  source = "image/png; some.file"
  should = "image/png"
  result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)

  source = "image/png;some.file"
  should = "image/png"
  result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)

  source = "image/jpeg;some.file"
  should = "image/jpeg"
  result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)

  source = "image/jpg;some.file"
  should = "image/jpg"
  result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)

  source = "image/gif;some.file"
  should = "image/gif"
  result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)

  source = "image/gif\n;some.file"
  should = "image/gif"
  result = App.Utils.contentTypeCleanup(source)
  equal(result, should, source)
});

// htmlImage2DataUrl
test("htmlImage2DataUrl", function() {

  var source = '<div>test 13</div>'
  var should = '<div>test 13</div>'
  var result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

  source = 'some test'
  should = 'some test'
  result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

  source = '<img src="some url">some test'
  should = '<img src="data:,">some test'
  result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

  source = '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAADAAEDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACv/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAF/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AbgQDv//Z">some test'
  should = '<img src="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAADAAEDAREAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACv/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAF/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AbgQDv//Z">some test'
  result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

  source = '<img src="data:image/jpeg;base64,some_data_123">some <img src="some url">test'
  should = '<img src="data:image/jpeg;base64,some_data_123">some <img src="data:,">test'
  result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

  // GitHub issue #2305
  source = '<img src="cid:1234">some test'
  should = '<img src="cid:1234">some test'
  result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

  // GitHub issue #2701
  source = '<img alt="foo">some test'
  should = '<img alt="foo">some test'
  result = App.Utils.htmlImage2DataUrl(source)
  equal(result, should, source)

});

test('App.Utils.icon()', function() {
  // When given no arguments,
  //   expect @icon() to return null
  equal(App.Utils.icon(), null, 'with no arguments')

  // On a modern browser and when given a single argument,
  //   expect @icon(name) to return an <svg> tag
  window.svgPolyfill = false
  svgTag = '<svg class="icon icon-foo "><use xlink:href="assets/images/icons.svg#icon-foo" /></svg>'
  equal(App.Utils.icon('foo'), svgTag, 'with one arg / no SVG polyfill')

  // On a modern browser and when given two arguments,
  //   expect @icon(name) to return an <svg> tag
  //   with second arg as add'l class name
  window.svgPolyfill = false
  svgTag = '<svg class="icon icon-foo bar"><use xlink:href="assets/images/icons.svg#icon-foo" /></svg>'
  equal(App.Utils.icon('foo', 'bar'), svgTag, 'with two args / no SVG polyfill')

  // On a browser requiring SVG polyfill and when given a single argument,
  //   expect @icon(name, class) to return an <svg> tag
  //   with pathless xlink:href attr
  window.svgPolyfill = true
  svgTag = '<svg class="icon icon-foo "><use xlink:href="#icon-foo" /></svg>'
  equal(App.Utils.icon('foo'), svgTag, 'with one arg / SVG polyfill')

  // On a browser requiring SVG polyfill and when given two arguments,
  //   expect @icon(name, class) to return an <svg> tag
  //   with pathless xlink:href attr and second arg as add'l class name
  window.svgPolyfill = true
  svgTag = '<svg class="icon icon-foo bar"><use xlink:href="#icon-foo" /></svg>'
  equal(App.Utils.icon('foo', 'bar'), svgTag, 'with two args / SVG polyfill')

  // For a left-to-right browser language and when given an argument containing '{start}' or '{end}',
  //   expect @icon(name) to return an <svg> tag
  //   replacing '{start}' with 'left' and '{end}' with 'right'
  window.svgPolyfill = false
  App.i18n.dir = function() { return 'ltr' }
  svgTag = '<svg class="icon icon-arrow-left "><use xlink:href="assets/images/icons.svg#icon-arrow-left" /></svg>'
  equal(App.Utils.icon('arrow-{start}'), svgTag, 'for ltr locale / name includes "{start}"')
  svgTag = '<svg class="icon icon-arrow-right "><use xlink:href="assets/images/icons.svg#icon-arrow-right" /></svg>'
  equal(App.Utils.icon('arrow-{end}'), svgTag, 'for ltr locale / name includes "{end}"')

  // For a right-to-left browser language and when given an argument containing '{start}' or '{end}',
  //   expect @icon(name) to return an <svg> tag
  //   replacing '{start}' with 'left' and '{end}' with 'right'
  window.svgPolyFill = false
  App.i18n.dir = function() { return 'rtl' }
  svgTag = '<svg class="icon icon-arrow-right "><use xlink:href="assets/images/icons.svg#icon-arrow-right" /></svg>'
  equal(App.Utils.icon('arrow-{start}'), svgTag, 'for rtl locale / name includes "{start}"')
  svgTag = '<svg class="icon icon-arrow-left "><use xlink:href="assets/images/icons.svg#icon-arrow-left" /></svg>'
  equal(App.Utils.icon('arrow-{end}'), svgTag, 'for rtl locale / name includes "{end}"')
});

var source1 = '<img src="/assets/images/avatar-bg.png">some test'
$('#image2data1').html(source1)
var htmlImage2DataUrlTest1 = function() {
  test("htmlImage2DataUrl1 async", function() {
    var result1 = App.Utils.htmlImage2DataUrl(source1)
    ok(result1.match(/some test/), source1)
    ok(!result1.match(/avatar-bg.png/), source1)
    ok(result1.match(/^\<img src=\"data:image\/png;base64,/), source1)
  });
}
$('#image2data1 img').one('load', htmlImage2DataUrlTest1)


var source2 = '<img src="/assets/images/chat-demo-avatar.png">some test'
$('#image2data2').html(source2)
var htmlImage2DataUrlTest2Success = function(element) {
  test('htmlImage2DataUrl2 async', function() {
    ok(!$(element).html().match(/chat-demo-avatar/), source2)
    ok($(element).get(0).outerHTML.match(/^\<img src=\"data:image\/png;base64,/), source2)
    ok($(element).attr('style'), 'max-width: 100%;')
  });
}
var htmlImage2DataUrlTest2Fail = function() {
  test('htmlImage2DataUrl2 async', function() {
    ok(false, 'fail callback is exectuted!')
  });
}
App.Utils.htmlImage2DataUrlAsyncInline($('#image2data2'), {success: htmlImage2DataUrlTest2Success, fail: htmlImage2DataUrlTest2Fail})

}

test('App.Utils.baseUrl()', function() {
  configGetBackup = App.Config.get

  // When FQDN is undefined or null,
  //   expect @baseUrl() to return window.location.origin
  App.Config.get = function(key) { return undefined }
  equal(App.Utils.baseUrl(), window.location.origin, 'with undefined FQDN')
  App.Config.get = function(key) { return null }
  equal(App.Utils.baseUrl(), window.location.origin, 'with null FQDN')

  // When FQDN is zammad.example.com,
  //   expect @baseUrl() to return window.location.origin
  App.Config.get = function(key) {
    if (key === 'fqdn') {
      return 'zammad.example.com'
    }
  }
  equal(App.Utils.baseUrl(), window.location.origin, 'with FQDN zammad.example.com')

  // Otherwise,
  //   expect @baseUrl() to return FQDN with current HTTP(S) scheme
  App.Config.get = function(key) {
    if (key === 'fqdn') {
      return 'foo.zammad.com'
    } else if (key === 'http_type') {
      return 'https'
    }
  }
  equal(App.Utils.baseUrl(), 'https://foo.zammad.com', 'with any other FQDN (and https scheme)')

  App.Config.get = function(key) {
    if (key === 'fqdn') {
      return 'bar.zammad.com'
    } else if (key === 'http_type') {
      return 'http'
    }
  }
  equal(App.Utils.baseUrl(), 'http://bar.zammad.com', 'with any other FQDN (and http scheme)')

  App.Config.get = configGetBackup
});

test('App.Utils.joinUrlComponents()', function() {
  // When given a list of strings,
  //   expect @joinUrlComponents() to join them with slashes
  equal(App.Utils.joinUrlComponents('foo', 'bar', 'baz'), 'foo/bar/baz', 'with a destructured list of strings')

  // When given an array of strings,
  //   expect @joinUrlComponents() to join them with slashes
  equal(App.Utils.joinUrlComponents(['foo', 'bar', 'baz']), 'foo/bar/baz', 'with an array of strings')

  // When given a list of many types,
  //   expect @joinUrlComponents() to join their string representations with slashes
  equal(App.Utils.joinUrlComponents(0, 1, 'two', true, false, { foo: 'bar' }), '0/1/two/true/false/[object Object]', 'with a list of many types')

  // When given a list including null or undefined,
  //   expect @joinUrlComponents() to filter them out of the results before joining the rest with slashes
  equal(App.Utils.joinUrlComponents('foo', undefined, 'bar', null, 'baz'), 'foo/bar/baz', 'with a list including null or undefined')
});

test('App.Utils.clipboardHtmlIsWithText()', function() {

  // no content with text
  equal(App.Utils.clipboardHtmlIsWithText('<div></div>'), false)
  equal(App.Utils.clipboardHtmlIsWithText('<div> </div>'), false)
  equal(App.Utils.clipboardHtmlIsWithText('<div><img src="test.jpg"/></div>'), false)
  equal(App.Utils.clipboardHtmlIsWithText('<div><!-- some comment --></div>'), false)
  equal(App.Utils.clipboardHtmlIsWithText('<div><!-- some comment --> </div>'), false)
  equal(App.Utils.clipboardHtmlIsWithText("<div><!-- some comment --> \n </div>"), false)

  // content with text
  equal(App.Utils.clipboardHtmlIsWithText('test'), true)
  equal(App.Utils.clipboardHtmlIsWithText('<div>test</div>'), true)
  equal(App.Utils.clipboardHtmlIsWithText('<meta http-equiv="content-type" content="text/html; charset=utf-8">sometext'), true)
});

test('App.Utils.clipboardHtmlInsertPreperation()', function() {
  equal(App.Utils.clipboardHtmlInsertPreperation('<div></div>', {}), '')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div> </div>', {}), ' ')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div><img src="test.jpg"/></div>', {}), '<img src="test.jpg">')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div><!-- some comment --></div>', {}), '')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div><!-- some comment --> </div>', {}), ' ')
  equal(App.Utils.clipboardHtmlInsertPreperation("<div><!-- some comment --> \n </div>", {}), " \n ")
  equal(App.Utils.clipboardHtmlInsertPreperation('test', {}), 'test')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div>test</div>', {}), 'test')
  equal(App.Utils.clipboardHtmlInsertPreperation('<meta http-equiv="content-type" content="text/html; charset=utf-8">sometext', {}), '<div>sometext</div>')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div><b>test</b> 123</div>', { mode: 'textonly' }), 'test 123')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div><b>test</b><br> 123</div>', { mode: 'textonly' }), 'test 123')
  equal(App.Utils.clipboardHtmlInsertPreperation('<div><b>test</b><br> 123</div>', { mode: 'textonly', multiline: true }), 'test<br> 123')
});

test('App.Utils.signatureIdentifyByHtmlHelper()', function() {
  result = App.Utils.signatureIdentifyByHtmlHelper("&lt;script&gt;alert('fish2');&lt;/script&gt;<blockquote></blockquote>")

  equal(result, "&lt;script&gt;alert('fish2');&lt;/script&gt;<span class=\"js-signatureMarker\"></span><blockquote></blockquote>", 'signatureIdentifyByHtmlHelper does not reactivate alert')
});

test("#safeParseHtml", function() {
  var unwrap = input => $('<div>').html(input)[0].innerHTML

  var html = "<div>test 123 </div>"
  var result  = App.Utils.safeParseHtml(html)
  var should = html
  equal(unwrap(result), html)


  // test if, according to jQuery, invalid HTML does not cause a a crash
  // https://github.com/zammad/zammad/issues/3393
  html   = "<td></td><table></table><div>test 123 </div>"
  should = "<table></table><div>test 123 </div>"
  result = App.Utils.safeParseHtml(html)
  equal(unwrap(result), should)
})
