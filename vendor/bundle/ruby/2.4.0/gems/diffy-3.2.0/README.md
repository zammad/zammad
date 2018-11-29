Diffy - Easy Diffing With Ruby [![Build Status](https://travis-ci.org/samg/diffy.svg?branch=master)](https://travis-ci.org/samg/diffy)
============================

Need diffs in your ruby app?  Diffy has you covered.  It provides a convenient
way to generate a diff from two strings or files.  Instead of reimplementing
the LCS diff algorithm Diffy uses battle tested Unix diff to generate diffs,
and focuses on providing a convenient interface, and getting out of your way.

Supported Formats
-----------------

It provides several built in format options which can be passed to
`Diffy::Diff#to_s`.

* `:text`         - Plain text output
* `:color`        - ANSI colorized text suitable for use in a terminal
* `:html`         - HTML output.  Since version 2.0 this format does inline highlighting of the character changes between lines.
* `:html_simple`  - HTML output without inline highlighting.  This may be useful in situations where high performance is required or simpler output is desired.

A default format can be set like so:

    Diffy::Diff.default_format = :html

Installation
------------

###on Unix

    gem install diffy

###on Windows:

1.  Ensure that you have a working `diff` on your machine and in your search path.

    There are several options:

	1.  Install [Diff::LCS](https://github.com/halostatue/diff-lcs), which includes `ldiff`. [RSpec](https://www.relishapp.com/rspec/docs/gettingstarted)
		depends on Diff::LCS so you may already have it installed.
		
	1.  If you're using [RubyInstaller](http://rubyinstaller.org), install the [devkit](http://rubyinstaller.org/add-ons/devkit).

	1.  Install unxutils <http://sourceforge.net/projects/unxutils>

        note that these tools contain diff 2.7 which has a different handling
        of whitespace in the diff results. This makes Diffy spec tests
        yielding one fail on Windows.

    1.  Install these two individually from the gnuwin32 project
        <http://gnuwin32.sourceforge.net/>

        note that this delivers diff 2.8 which makes Diffy spec pass
        even on Windows.


2.   Install the gem by

         gem install diffy


Getting Started
---------------

Here's an example of using Diffy to diff two strings

    $ irb
    >> string1 = <<-TXT
    >" Hello how are you
    >" I'm fine
    >" That's great
    >" TXT
    => "Hello how are you\nI'm fine\nThat's great\n"
    >> string2 = <<-TXT
    >" Hello how are you?
    >" I'm fine
    >" That's swell
    >" TXT
    => "Hello how are you?\nI'm fine\nThat's swell\n"
    >> puts Diffy::Diff.new(string1, string2)
    -Hello how are you
    +Hello how are you?
     I'm fine
    -That's great
    +That's swell

HTML Output
---------------

Outputing the diff as html is easy too.  Here's an example using the
`:html_simple` formatter.

    >> puts Diffy::Diff.new(string1, string2).to_s(:html_simple)
    <div class="diff">
      <ul>
        <li class="del"><del>Hello how are you</del></li>
        <li class="ins"><ins>Hello how are you?</ins></li>
        <li class="unchanged"><span>I'm fine</span></li>
        <li class="del"><del>That's great</del></li>
        <li class="ins"><ins>That's swell</ins></li>
      </ul>
    </div>

The `:html` formatter will give you inline highlighting a la github.

    >> puts Diffy::Diff.new("foo\n", "Foo\n").to_s(:html)
    <div class="diff">
      <ul>
        <li class="del"><del><strong>f</strong>oo</del></li>
        <li class="ins"><ins><strong>F</strong>oo</ins></li>
      </ul>
    </div>

There's some pretty nice css provided in `Diffy::CSS`.

    >> puts Diffy::CSS
    .diff{overflow:auto;}
    .diff ul{background:#fff;overflow:auto;font-size:13px;list-style:none;margin:0;padding:0;display:table;width:100%;}
    .diff del, .diff ins{display:block;text-decoration:none;}
    .diff li{padding:0; display:table-row;margin: 0;height:1em;}
    .diff li.ins{background:#dfd; color:#080}
    .diff li.del{background:#fee; color:#b00}
    .diff li:hover{background:#ffc}
    /* try 'whitespace:pre;' if you don't want lines to wrap */
    .diff del, .diff ins, .diff span{white-space:pre-wrap;font-family:courier;}
    .diff del strong{font-weight:normal;background:#fcc;}
    .diff ins strong{font-weight:normal;background:#9f9;}
    .diff li.diff-comment { display: none; }
    .diff li.diff-block-info { background: none repeat scroll 0 0 gray; }


There's also a colorblind-safe version of the pallete provided in `Diffy::CSS_COLORBLIND_1`.


Side-by-side comparisons
------------------------

Side-by-side comparisons, or split views as called by some, are supported by
using the `Diffy::SplitDiff` class.  This class takes a diff returned from
`Diffy::Diff` and splits it in two parts (or two sides): left and right.  The
left side represents deletions while the right side represents insertions.

The class is used as follows:

```
Diffy::SplitDiff.new(string1, string2, options = {})
```

The optional options hash is passed along to the main `Diff::Diff` class, so
all default options such as full diff output are supported.  The output format
may be changed by passing the format with the options hash (see below), and all
default formats are supported.

Unlike `Diffy::Diff`, `Diffy::SplitDiff` does not use `#to_s` to output
the resulting diff.  Instead, two self-explanatory methods are used to output
the diff: `#left` and `#right`.  Using the earlier example, this is what they
look like in action:

```
>> puts Diffy::SplitDiff.new(string1, string2).left
-Hello how are you
 I'm fine
-That's great
```

```
>> puts Diffy::SplitDiff.new(string1, string2).right
+Hello how are you?
 I'm fine
+That's swell
```

### Changing the split view output format

The output format may be changed by passing the format with the options hash:

```
Diffy::SplitDiff.new(string1, string2, :format => :html)
```

This will result in the following:

```
>> puts Diffy::SplitDiff.new(string1, string2, :format => :html).left
<div class="diff">
  <ul>
    <li class="del"><del>Hello how are you</del></li>
    <li class="unchanged"><span>I&#39;m fine</span></li>
    <li class="del"><del>That&#39;s <strong>great</strong></del></li>
  </ul>
</div>
```

```
>> puts Diffy::SplitDiff.new(string1, string2, :format => :html).right
<div class="diff">
  <ul>
    <li class="ins"><ins>Hello how are you<strong>?</strong></ins></li>
    <li class="unchanged"><span>I&#39;m fine</span></li>
    <li class="ins"><ins>That&#39;s <strong>swell</strong></ins></li>
  </ul>
</div>
```


Other Diff Options
------------------

### Diffing files instead of strings

You can diff files instead of strings by using the `:source` option.

    >> puts Diffy::Diff.new('/tmp/foo', '/tmp/bar', :source => 'files')

### Full Diff Output

By default Diffy removes the superfluous diff output.  This is because its
default is to show the complete diff'ed file (`diff -U 10000` is the default).

Diffy does support full output, just use the `:include_diff_info => true`
option when initializing:

    >> Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n", :include_diff_info => true).to_s(:text)
    =>--- /Users/chaffeqa/Projects/stiwiki/tmp/diffy20111116-82153-ie27ex	2011-11-16 20:16:41.000000000 -0500
    +++ /Users/chaffeqa/Projects/stiwiki/tmp/diffy20111116-82153-wzrhw5	2011-11-16 20:16:41.000000000 -0500
    @@ -1,2 +1,3 @@
     foo
     bar
    +baz

And even deals a bit with the formatting!

### Empty Diff Behavior

By default Diffy will return empty string if there are no
differences in inputs. In previous versions the full text of its first input
was returned in this case. To restore this behaviour simply use the
`:allow_empty_diff => false` option when initializing.

### Plus and Minus symbols in HTML output

By default Diffy doesn't include the `+`, `-`, and ` ` at the beginning of line for
HTML output.

You can use the `:include_plus_and_minus_in_html` option to include those
symbols in the output.

    >> puts Diffy::Diff.new(string1, string2, :include_plus_and_minus_in_html => true).to_s(:html_simple)
    <div class="diff">
      <ul>
        <li class="del"><del><span class="symbol">-</span>Hello how are you</del></li>
        <li class="ins"><ins><span class="symbol">+</span>Hello how are you?</ins></li>
        <li class="unchanged"><span class="symbol"> </span><span>I'm fine</span></li>
        <li class="del"><del><span class="symbol">-</span>That's great</del></li>
        <li class="ins"><ins><span class="symbol">+</span>That's swell</ins></li>
      </ul>
    </div>

### Number of lines of context around changes

You can use the `:context` option to override the number of lines of context
that are shown around each change (this defaults to 10000 to show the full
file).

    >> puts Diffy::Diff.new("foo\nfoo\nBAR\nbang\nbaz", "foo\nfoo\nbar\nbang\nbaz", :context => 1)
     foo
    -BAR
    +bar
     bang


### Overriding the command line options passed to diff.

You can use the `:diff` option to override the command line options that are
passed to unix diff. They default to `-U 10000`.  This option will noop if
combined with the `:context` option.

    >> puts Diffy::Diff.new(" foo\nbar\n", "foo\nbar\n", :diff => "-w")
      foo
     bar

Default Diff Options
--------------------

You can set the default options for new `Diffy::Diff`s using the
`Diffy::Diff.default_options` and `Diffy::Diff.default_options=` methods.
Options passed to `Diffy::Diff.new` will be merged into the default options.

    >> Diffy::Diff.default_options
    => {:diff=>"-U 10000", :source=>"strings", :include_diff_info=>false, :include_plus_and_minus_in_html=>false}
    >> Diffy::Diff.default_options.merge!(:source => 'files')
    => {:diff=>"-U 10000", :source=>"files", :include_diff_info=>false, :include_plus_and_minus_in_html=>false}


Custom Formats
--------------

Diffy tries to make generating your own custom formatted output easy.
`Diffy::Diff` provides an enumerable interface which lets you iterate over
lines in the diff.

    >> Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each do |line|
    >*   case line
    >>   when /^\+/ then puts "line #{line.chomp} added"
    >>   when /^-/ then puts "line #{line.chomp} removed"
    >>   end
    >> end
    line +baz added
    => [" foo\n", " bar\n", "+baz\n"]

You can also use `Diffy::Diff#each_chunk` to iterate each grouping of additions,
deletions, and unchanged in a diff.

    >> Diffy::Diff.new("foo\nbar\nbang\nbaz\n", "foo\nbar\nbing\nbong\n").each_chunk.to_a
    => [" foo\n bar\n", "-bang\n-baz\n", "+bing\n+bong\n"]

Use `#map`, `#inject`, or any of Enumerable's methods.  Go crazy.


Testing
------------

Diffy includes a full set of rspec tests.  When contributing please include
tests for your changes.

[![Build Status](https://secure.travis-ci.org/samg/diffy.png)](http://travis-ci.org/samg/diffy)

---------------------------------------------------------------------

Report bugs or request features at http://github.com/samg/diffy/issues

