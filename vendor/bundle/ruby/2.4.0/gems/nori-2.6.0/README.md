Nori
====

[![Build Status](https://secure.travis-ci.org/savonrb/nori.png)](http://travis-ci.org/savonrb/nori)
[![Gem Version](https://badge.fury.io/rb/nori.png)](http://badge.fury.io/rb/nori)
[![Code Climate](https://codeclimate.com/github/savonrb/nori.png)](https://codeclimate.com/github/savonrb/nori)
[![Coverage Status](https://coveralls.io/repos/savonrb/nori/badge.png?branch=master)](https://coveralls.io/r/savonrb/nori)


Really simple XML parsing ripped from Crack which ripped it from Merb.  
Nori was created to bypass the stale development of Crack, improve its XML parser  
and fix certain issues.

``` ruby
parser = Nori.new
parser.parse("<tag>This is the contents</tag>")
# => { 'tag' => 'This is the contents' }
```

Nori supports pluggable parsers and ships with both REXML and Nokogiri implementations.  
It defaults to Nokogiri since v2.0.0, but you can change it to use REXML via:

``` ruby
Nori.new(:parser => :rexml)  # or :nokogiri
```

Make sure Nokogiri is in your LOAD_PATH when parsing XML, because Nori tries to load it  
when it's needed.


Typecasting
-----------

Besides regular typecasting, Nori features somewhat "advanced" typecasting:

* "true" and "false" String values are converted to `TrueClass` and `FalseClass`.
* String values matching xs:time, xs:date and xs:dateTime are converted
  to `Time`, `Date` and `DateTime` objects.

You can disable this feature via:

``` ruby
Nori.new(:advanced_typecasting => false)
```


Namespaces
----------

Nori can strip the namespaces from your XML tags. This feature might raise  
problems and is therefore disabled by default. Enable it via:

``` ruby
Nori.new(:strip_namespaces => true)
```


XML tags -> Hash keys
---------------------

Nori lets you specify a custom formula to convert XML tags to Hash keys.  
Let me give you an example:

``` ruby
parser = Nori.new(:convert_tags_to => lambda { |tag| tag.snakecase.to_sym })

xml = '<userResponse><accountStatus>active</accountStatus></userResponse>'
parser.parse(xml)  # => { :user_response => { :account_status => "active" }
```

Dashes and underscores
----------------------

Nori will automatically convert dashes in tag names to underscores.
For example:

```ruby
parser = Nori.new
parser.parse('<any-tag>foo bar</any-tag>')  # => { "any_tag" => "foo bar" }
```

You can control this behavior with the `:convert_dashes_to_underscores` option:

```ruby
parser = Nori.new(:convert_dashes_to_underscores => false)
parser.parse('<any-tag>foo bar</any-tag>') # => { "any-tag" => "foo bar" }
```
