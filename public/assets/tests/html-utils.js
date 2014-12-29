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

});

}