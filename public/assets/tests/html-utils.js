window.onload = function() {

// textCleanup
test( "textCleanup", function() {

  var source = "Some\nValue\n\n\nTest"
  var should = "Some\nValue\n\nTest"
  var result = App.Utils.textCleanup( source )
  equal( result, should, source )

  source = "Some\nValue\n\n \n\n\nTest"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup( source )
  equal( result, should, source )

  source = "Some\n\rValue\n\r\n\r\n\rTest"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup( source )
  equal( result, should, source )

  source = "Some\n\rValue\n\r\n\r\n\rTest\r"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup( source )
  equal( result, should, source )

  source = "Some\r\nValue\r\n\r\n\r\nTest\r\n"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup( source )
  equal( result, should, source )

  source = "Some\r\nValue\r\n\r\n\r\n\r\n\r\n\r\nTest\r\n"
  should = "Some\nValue\n\nTest"
  result = App.Utils.textCleanup( source )
  equal( result, should, source )

  source = "> Welcome!\n> \n> Thank you for installing Zammad.\n> \n> You will find ..."
  should = "> Welcome!\n>\n> Thank you for installing Zammad.\n>\n> You will find ..."
  result = App.Utils.textCleanup( source )
  equal( result, should, source )


});

// text2html
test( "text2html", function() {

  var source = "Some\nValue\n\n\nTest"
  var should = "<div>Some</div><div>Value</div><div><br></div><div>Test</div>"
  var result = App.Utils.text2html( source )
  equal( result, should, source )

  source = "Some\nValue\n"
  should = "<div>Some</div><div>Value</div>"
  result = App.Utils.text2html( source )
  equal( result, should, source )

  source = "Some\n<b>Value</b>\n"
  should = "<div>Some</div><div>&lt;b&gt;Value&lt;/b&gt;</div>"
  result = App.Utils.text2html( source )
  equal( result, should, source )

  source = "> Welcome!\n> \n> Thank you for installing Zammad.\n> \n> You will find ..."
  should = "<div>&gt; Welcome!</div><div>&gt;</div><div>&gt; Thank you for installing Zammad.</div><div>&gt;</div><div>&gt; You will find ...</div>"
  result = App.Utils.text2html( source )
  equal( result, should, source )

});

// linkify
test( "linkify", function() {

  var source = "http://example.com"
  var should = '<a href="http://example.com" title="http://example.com" target="_blank">http://example.com</a>'
  var result = App.Utils.linkify( source )
  equal( result, should, source )

  source = "http://example.com?some_param=lalala"
  should = '<a href="http://example.com?some_param=lalala" title="http://example.com?some_param=lalala" target="_blank">http://example.com?some_param=lalala</a>'
  result = App.Utils.linkify( source )
  equal( result, should, source )

  source = "example.com"
  should = '<a href="http://example.com" title="http://example.com" target="_blank">example.com</a>'
  result = App.Utils.linkify( source )
  equal( result, should, source )

  source = "some text example.com"
  should = 'some text <a href="http://example.com" title="http://example.com" target="_blank">example.com</a>'
  result = App.Utils.linkify( source )
  equal( result, should, source )

  source = "example.com some text"
  should = '<a href="http://example.com" title="http://example.com" target="_blank">example.com</a> some text'
  result = App.Utils.linkify( source )
  equal( result, should, source )


  /*
  source = "<b>example.com</b>"
  should = '<b><a href="http://example.com" title="http://example.com" target="_blank">http://example.com</a></b>'
  result = App.Utils.linkify( source )
  equal( result, should, source )
  */

});

// htmlEscape
test( "htmlEscape", function() {

  var source = "<"
  var should = "&lt;"
  var result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = ">"
  should = "&gt;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "&"
  should = "&amp;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "&amp;"
  should = "&amp;amp;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "&amp ;"
  should = "&amp;amp ;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "& amp;"
  should = "&amp; amp;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "'test'"
  should = "&#39;test&#39;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = '"test"'
  should = "&quot;test&quot;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "<>"
  should = "&lt;&gt;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

  source = "<&lt;>"
  should = "&lt;&amp;lt;&gt;"
  result = App.Utils.htmlEscape( source )
  equal( result, should, source )

});

// htmlRemoveTags
test( "htmlRemoveTags", function() {

  var source = "<div>test</div>"
  var should = "test"
  var result = App.Utils.htmlRemoveTags( $(source) )
  equal( result.html(), should, source )

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveTags( $(source) )
  equal( result.html(), should, source )

  source = "<div><a href=\"some_link\">some link to somewhere</a></div>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveTags( $(source) )
  equal( result.html(), should, source )

  source = "<div><a href=\"some_link\">some link to somewhere</a><input value=\"should not be shown\"></div>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveTags( $(source) )
  equal( result.html(), should, source )

  source = "<div><a href=\"some_link\">some link to somewhere</a> <div><hr></div> <span>123</span> <img src=\"some_image\"/></div>"
  should = "some link to somewhere  123 "
  result = App.Utils.htmlRemoveTags( $(source) )
  equal( result.html(), should, source )

  source = "<div><form class=\"xxx\">test 123</form></div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><textarea class=\"xxx\">test 123</textarea></div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )
});

// htmlRemoveRichtext
test( "htmlRemoveRichtext", function() {

  var source = "<div><a href=\"test\">test</a></div>"
  var should = "test"
  var result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><a href=\"some_link\"></a> test </div>"
  should = " test "
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><b></b> test </div>"
  should = " test "
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><div><b></b> test </div></div>"
  should = "<div> test </div>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><div><b></b> test <input value=\"should not be shown\"></div></div>"
  should = "<div> test </div>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><div><b></b> test </div><span>123</span></div>"
  should = "<div> test </div><span>123</span>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><div class=\"xxx\"><b></b> test </div></div>"
  should = "<div> test </div>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><textarea class=\"xxx\"> test </textarea></div>"
  //should = "<div> test </div>"
  should = " test "
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><br></div>"
  should = "<br>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><div class=\"xxx\"><br></div></div>"
  should = "<div><br></div>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><form class=\"xxx\">test 123</form></div>"
  //should = "<div>test 123</div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )


});

// htmlClanup
test( "htmlClanup", function() {

  var source = "<div><a href=\"test\">test</a></div>"
  var should = "test"
  var result = App.Utils.htmlClanup( $(source) )
  equal( result.html(), should, source )

  source = "<a href=\"some_link\">some link to somewhere</a>"
  should = "some link to somewhere"
  result = App.Utils.htmlClanup( $(source) )
  equal( result.html(), should, source )

  source = "<div><h1>some link to somewhere</h1></a>"
  should = "<div>some link to somewhere</div>"
  result = App.Utils.htmlClanup( $(source) )
  equal( result.html(), should, source )

  source = "<div><h1>some link to somewhere</h1><p><hr></p></div>"
  should = "<div>some link to somewhere</div><p></p><p></p>"
  result = App.Utils.htmlClanup( $(source) )
  equal( result.html(), should, source )

  source = "<div><br></div>"
  should = "<br>"
  result = App.Utils.htmlClanup( $(source) )
  equal( result.html(), should, source )

  source = "<div><div class=\"xxx\"><br></div></div>"
  should = "<div><br></div>"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><form class=\"xxx\">test 123</form></div>"
  //should = "<div>test 123<br></div>"
  should = "test 123"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><form class=\"xxx\">test 123</form> some other value</div>"
  //should = "<div>ttest 123 some other value</div>"
  should = "test 123 some other value"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><form class=\"xxx\">test 123</form> some other value<input value=\"should not be shown\"></div>"
  //should = "<div>test 123 some other value</div>"
  should = "test 123 some other value"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

  source = "<div><font size=\"3\" color=\"red\">This is some text!</font></div>"
  //should = "<div>This is some text!</div>"
  should = "This is some text!"
  result = App.Utils.htmlRemoveRichtext( $(source) )
  equal( result.html(), should, source )

});

// wrap
test( "wrap", function() {

  var source = "some text"
  var should = 'some text'
  var result = App.Utils.wrap( source )
  equal( result, should, source )

  source = "some text\nsome other text\n"
  should = "some text\nsome other text\n"
  result = App.Utils.wrap( source )
  equal( result, should, source )

  source = "some text with some line to wrap"
  should = "some text with\nsome line to\nwrap"
  result = App.Utils.wrap( source, 14 )
  equal( result, should, source )

  source = "some text\nsome other text\n"
  should = "some text\nsome other text\n"
  result = App.Utils.wrap( source )
  equal( result, should, source )

  source = "1234567890 1234567890 1234567890 1234567890"
  should = "1234567890 1234567890 1234567890 1234567890"
  result = App.Utils.wrap( source )
  equal( result, should, source )

  source = "123456789012 123456789012 123456789012"
  should = "123456789012\n123456789012\n123456789012"
  result = App.Utils.wrap( source, 14 )
  equal( result, should, source )

});

// quote
test( "quote", function() {

  var source = "some text"
  var should = '> some text'
  var result = App.Utils.quote( source )
  equal( result, should, source )

  source = "some text\nsome other text\n"
  should = "> some text\n> some other text"
  result = App.Utils.quote( source )
  equal( result, should, source )

  source = "\n\nsome text\nsome other text\n \n"
  should = "> some text\n> some other text"
  result = App.Utils.quote( source )
  equal( result, should, source )

  source = "Welcome!\n\nThank you for installing Zammad.\n\nYou will find ..."
  should = "> Welcome!\n>\n> Thank you for installing Zammad.\n>\n> You will find ..."
  result = App.Utils.quote( source )
  equal( result, should, source )


  source = "Welcome! Thank you for installing Zammad. You will find ..."
  should = "> Welcome! Thank you\n> for installing\n> Zammad. You will\n> find ..."
  result = App.Utils.quote( source, 20 )
  equal( result, should, source )


});

// check signature
test( "check signature", function() {

  var message   = "<div>test 123 </div>"
  var signature = '<div>--<br>Some Signature<br>some department</div>'
  var result    = App.Utils.signatureCheck( message, signature )
  equal( result, true )

  message   = "<div>test 123 <div>--<br>Some Signature<br>some department\n</div></div>"
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck( message, signature )
  equal( result, false )

  message   = "<div>test 123 <div>--<br>Some Signature\n<br>some department\n</div></div>"
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck( message, signature )
  equal( result, false )

  message   = "<div>test 123 <div>--<p>Some Signature</p>\n<p><div>some department</div>\n</p>\n</div></div>"
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck( message, signature )
  equal( result, false )

  message   = ""
  signature = '<div>--<br>Some Signature<br>some department</div>'
  result    = App.Utils.signatureCheck( message, signature )
  equal( result, true )

  message   = ""
  signature = "--\nSome Signature\nsome department"
  result    = App.Utils.signatureCheck( message, signature )
  equal( result, true )

});

}