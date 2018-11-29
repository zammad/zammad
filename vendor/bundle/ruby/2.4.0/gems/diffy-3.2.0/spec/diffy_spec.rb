require 'rspec'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'diffy'))

describe Diffy::Diff do

  describe "diffing two files" do
    def tempfile(string, fn = 'diffy-spec')
      t = Tempfile.new(fn)
      # ensure tempfiles aren't unlinked when GC runs by maintaining a
      # reference to them.
      @tempfiles ||=[]
      @tempfiles.push(t)
      t.print(string)
      t.flush
      t.close
      t.path
    end

    it "should accept file paths as arguments" do
      string1 = "foo\nbar\nbang\n"
      string2 = "foo\nbang\n"
      path1, path2 = tempfile(string1), tempfile(string2)
      expect(Diffy::Diff.new(path1, path2, :source => 'files').to_s).to eq <<-DIFF
 foo
-bar
 bang
      DIFF
    end

    it "should accept file paths with spaces as arguments" do
      string1 = "foo\nbar\nbang\n"
      string2 = "foo\nbang\n"
      path1, path2 = tempfile(string1, 'path with spaces'), tempfile(string2, 'path with spaces')
      expect(Diffy::Diff.new(path1, path2, :source => 'files').to_s).to eq <<-DIFF
 foo
-bar
 bang
      DIFF
    end

    it "should accept file paths with spaces as arguments on windows" do
      begin

        orig_verbose, $VERBOSE = $VERBOSE, nil #silence redefine constant warnings
        orig_windows, Diffy::WINDOWS = Diffy::WINDOWS, true
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        path1, path2 = tempfile(string1, 'path with spaces'), tempfile(string2, 'path with spaces')
        expect(Diffy::Diff.new(path1, path2, :source => 'files').to_s).to eq <<-DIFF
 foo
-bar
 bang
        DIFF
      ensure
        Diffy::WINDOWS, $VERBOSE = orig_windows, orig_verbose
      end

    end

    describe "with no line different" do
      before do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbar\nbang\n"
        @path1, @path2 = tempfile(string1), tempfile(string2)
      end

      it "should show everything" do
        expect(Diffy::Diff.new(@path1, @path2, :source => 'files', :allow_empty_diff => false).
          to_s).to eq <<-DIFF
 foo
 bar
 bang
        DIFF
      end

      it "should not show everything if the :allow_empty_diff option is set" do
        expect(Diffy::Diff.new(@path1, @path2, :source => 'files', :allow_empty_diff => true).to_s).to eq('')
      end
    end
    describe "with lines that start with backslashes" do
      before do
        string1 = "foo\n\\\\bag\nbang\n"
        string2 = "foo\n\\\\bar\nbang\n"
        @path1, @path2 = tempfile(string1), tempfile(string2)
      end

      it "should not leave lines out" do
        expect(Diffy::Diff.new(@path1, @path2, :source => 'files').to_s).to eq <<-DIFF
 foo
-\\\\bag
+\\\\bar
 bang
        DIFF
      end
    end

     describe "with non valid UTF bytes" do
       before do
         string1 = "Foo ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000\n"
         string2 = "Bar ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000\n"
         @path1, @path2 = tempfile(string1), tempfile(string2)
       end
       it "should not raise invalid encoding issues" do
         desired = <<-DIFF
-Foo ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000
+Bar ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000
         DIFF
         desired.force_encoding("ASCII-8BIT") if desired.respond_to?(:force_encoding)
         expect(Diffy::Diff.new(@path1, @path2, :source => 'files').to_s).to eq(desired)
       end
     end

  end

  describe "handling temp files" do
    it "should unlink tempfiles after generating the diff" do
      before_tmpfiles = Dir.entries(Dir.tmpdir)
      ::Diffy::Diff.new("a", "b").to_s
      after_tmpfiles = Dir.entries(Dir.tmpdir)
      expect(before_tmpfiles).to match_array(after_tmpfiles)
    end

    it "should still be able to generate multiple diffs" do
      d = ::Diffy::Diff.new("a", "b")
      expect(d.to_s).to be_a String
      expect(d.to_s(:html)).to be_a String
    end
  end

  describe "options[:context]" do
    it "should limit context lines to 1" do
      diff = Diffy::Diff.new("foo\nfoo\nBAR\nbang\nbaz", "foo\nfoo\nbar\nbang\nbaz", :context => 1)
      expect(diff.to_s).to eq <<-DIFF
 foo
-BAR
+bar
 bang
      DIFF
    end
  end

  describe "options[:include_plus_and_minus_in_html]" do
    it "defaults to false" do
      @diffy = Diffy::Diff.new(" foo\nbar\n", "foo\nbar\n")
      expect(@diffy.options[:include_plus_and_minus_in_html]).to eq(false)
    end

    it "can be set to true" do
      @diffy = Diffy::Diff.new(" foo\nbar\n", "foo\nbar\n", :include_plus_and_minus_in_html=> true )
      expect(@diffy.options[:include_plus_and_minus_in_html]).to eq(true)
    end

    describe "formats" do
      it "includes symbols in html_simple" do
        output = Diffy::Diff.new("foo\nbar\nbang\n", "foo\nbang\n", :include_plus_and_minus_in_html => true ).
          to_s(:html_simple)
        expect(output).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span><span class="symbol"> </span>foo</span></li>
    <li class="del"><del><span class="symbol">-</span>bar</del></li>
    <li class="unchanged"><span><span class="symbol"> </span>bang</span></li>
  </ul>
</div>
        HTML
      end

      it "includes symbols in html" do
        output = Diffy::Diff.new("foo\nbar\nbang\n", "foo\naba\nbang\n", :include_plus_and_minus_in_html => true ).
          to_s(:html)
        expect(output).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span><span class="symbol"> </span>foo</span></li>
    <li class="del"><del><span class="symbol">-</span>ba<strong>r</strong></del></li>
    <li class="ins"><ins><span class="symbol">+</span><strong>a</strong>ba</ins></li>
    <li class="unchanged"><span><span class="symbol"> </span>bang</span></li>
  </ul>
</div>
        HTML
      end

    end

  end

  describe "options[:include_diff_info]" do
    it "defaults to false" do
      @diffy = Diffy::Diff.new(" foo\nbar\n", "foo\nbar\n")
      expect(@diffy.options[:include_diff_info]).to eq(false)
    end

    it "can be set to true" do
      @diffy = Diffy::Diff.new(" foo\nbar\n", "foo\nbar\n", :include_diff_info => true )
      expect(@diffy.options[:include_diff_info]).to eq(true)
    end

    it "includes all diff output" do
      output = Diffy::Diff.new("foo\nbar\nbang\n", "foo\nbang\n", :include_diff_info => true ).to_s
      expect(output.to_s).to match( /@@/)
      expect(output).to match( /---/)
      expect(output).to match( /\+\+\+/)
    end

    describe "formats" do
      it "works for :color" do
        output = Diffy::Diff.new("foo\nbar\nbang\n", "foo\nbang\n", :include_diff_info => true ).to_s(:color)
        expect(output).to match( /\e\[0m\n\e\[36m\@\@/ )
        expect(output.to_s).to match( /\e\[90m---/)
        expect(output.to_s).to match( /\e\[0m\n\e\[90m\+\+\+/)
      end

      it "works for :html_simple" do
        output = Diffy::Diff.new("foo\nbar\nbang\n", "foo\nbang\n", :include_diff_info => true ).to_s(:html_simple)
        expect(output.split("\n")).to include( "    <li class=\"diff-block-info\"><span>@@ -1,3 +1,2 @@</span></li>" )
        expect(output).to include( "<li class=\"diff-comment\"><span>---")
        expect(output).to include( "<li class=\"diff-comment\"><span>+++")
      end
    end
  end

  describe "options[:diff]" do
    it "should accept an option to diff" do
      @diff = Diffy::Diff.new(" foo\nbar\n", "foo\nbar\n", :diff => "-w", :allow_empty_diff => false)
      expect(@diff.to_s).to eq <<-DIFF
  foo
 bar
      DIFF
    end

    it "should accept multiple arguments to diff" do
      @diff = Diffy::Diff.new(" foo\nbar\n", "foo\nbaz\n", :diff => ["-w", "-U 3"])
      expect(@diff.to_s).to eq <<-DIFF
  foo
-bar
+baz
      DIFF
    end
  end

  describe "#to_s" do
    describe "with no line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbar\nbang\n"
      end

      it "should show everything" do
        expect(Diffy::Diff.new(@string1, @string2, :allow_empty_diff => false).to_s).to eq <<-DIFF
 foo
 bar
 bang
        DIFF
      end
    end
    describe "with one line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbang\n"
      end

      it "should show one line removed" do
        expect(Diffy::Diff.new(@string1, @string2).to_s).to eq <<-DIFF
 foo
-bar
 bang
        DIFF
      end

      it "to_s should accept a format key" do
        expect(Diffy::Diff.new(@string1, @string2).to_s(:color)).
          to eq(" foo\n\e[31m-bar\e[0m\n bang\n")
      end

      it "should accept a default format option" do
        old_format = Diffy::Diff.default_format
        Diffy::Diff.default_format = :color
        expect(Diffy::Diff.new(@string1, @string2).to_s).
          to eq(" foo\n\e[31m-bar\e[0m\n bang\n")
        Diffy::Diff.default_format = old_format
      end

      it "should accept a default options" do
        old_options = Diffy::Diff.default_options
        Diffy::Diff.default_options = old_options.merge(:include_diff_info => true)
        expect(Diffy::Diff.new(@string1, @string2).to_s).
          to include('@@ -1,3 +1,2 @@')
        Diffy::Diff.default_options = old_options
      end

      it "should show one line added" do
        expect(Diffy::Diff.new(@string2, @string1).to_s).
          to eq <<-DIFF
 foo
+bar
 bang
        DIFF
      end
    end

    describe "with one line changed" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbong\nbang\n"
      end
      it "should show one line added and one removed" do
        expect(Diffy::Diff.new(@string1, @string2).to_s).to eq <<-DIFF
 foo
-bar
+bong
 bang
        DIFF
      end
    end

    describe "with totally different strings" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "one\ntwo\nthree\n"
      end
      it "should show one line added and one removed" do
        expect(Diffy::Diff.new(@string1, @string2).to_s).to eq <<-DIFF
-foo
-bar
-bang
+one
+two
+three
        DIFF
      end
    end

    describe "with a somewhat complicated diff" do
      before do
        @string1 = "foo\nbar\nbang\nwoot\n"
        @string2 = "one\ntwo\nthree\nbar\nbang\nbaz\n"
        @diff = Diffy::Diff.new(@string1, @string2)
      end
      it "should show one line added and one removed" do
        expect(@diff.to_s).to eq <<-DIFF
-foo
+one
+two
+three
 bar
 bang
-woot
+baz
        DIFF
      end

      it "should make an awesome simple html diff" do
        expect(@diff.to_s(:html_simple)).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>foo</del></li>
    <li class="ins"><ins>one</ins></li>
    <li class="ins"><ins>two</ins></li>
    <li class="ins"><ins>three</ins></li>
    <li class="unchanged"><span>bar</span></li>
    <li class="unchanged"><span>bang</span></li>
    <li class="del"><del>woot</del></li>
    <li class="ins"><ins>baz</ins></li>
  </ul>
</div>
        HTML
      end

      it "should accept overrides to diff's options" do
        @diff = Diffy::Diff.new(@string1, @string2, :diff => "--rcs")
        expect(@diff.to_s).to eq <<-DIFF
d1 1
a1 3
one
two
three
d4 1
a4 1
baz
          DIFF
      end
    end

    describe "html" do
      it "should not allow html injection on the last line" do
        @string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n<script>\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz\n<script>\n"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
    <li class="unchanged"><span>&lt;script&gt;</span></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      it "should highlight the changes within the line" do
        @string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz\n"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      it "should not duplicate some lines" do
        @string1 = "hahaha\ntime flies like an arrow\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="ins"><ins><strong>bang baz</strong></ins></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      it "should escape html" do
        @string1 = "ha<br>haha\ntime flies like an arrow\n"
        @string2 = "ha<br>haha\nfruit flies like a banana\nbang baz"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>ha&lt;br&gt;haha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="ins"><ins><strong>bang baz</strong></ins></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      it "should not double escape html in wierd edge cases" do
        @string1 = "preface = (! title .)+ title &{YYACCEPT}\n"
        @string2 = "preface = << (! title .)+ title >> &{YYACCEPT}\n"
        @diff = Diffy::Diff.new @string1, @string2
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>preface = (! title .)+ title &amp;{YYACCEPT}</del></li>
    <li class="ins"><ins>preface = <strong>&lt;&lt; </strong>(! title .)+ title <strong>&gt;&gt; </strong>&amp;{YYACCEPT}</ins></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      it "should highlight the changes within the line with windows style line breaks" do
        @string1 = "hahaha\r\ntime flies like an arrow\r\nfoo bar\r\nbang baz\n"
        @string2 = "hahaha\r\nfruit flies like a banana\r\nbang baz\n"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      it "should treat unix vs windows newlines as differences" do
        @diff = Diffy::Diff.new("one\ntwo\nthree\n", "one\r\ntwo\r\nthree\r\n")
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>one</del></li>
    <li class="del"><del>two</del></li>
    <li class="del"><del>three</del></li>
    <li class="ins"><ins>one<strong></strong></ins></li>
    <li class="ins"><ins>two<strong></strong></ins></li>
    <li class="ins"><ins>three<strong></strong></ins></li>
  </ul>
</div>
        HTML
        expect(@diff.to_s(:html)).to eq(html)
      end

      describe 'with lines that include \n' do
        before do
          string1 = 'a\nb'"\n"

          string2 = 'acb'"\n"
          @string1, @string2 = string1, string2
        end

        it "should not leave lines out" do
          expect(Diffy::Diff.new(@string1, @string2 ).to_s(:html)).to eq <<-DIFF
<div class="diff">
  <ul>
    <li class="del"><del>a<strong>\\n</strong>b</del></li>
    <li class="ins"><ins>a<strong>c</strong>b</ins></li>
  </ul>
</div>
          DIFF
        end
      end

      it "should do highlighting on the last line when there's no trailing newlines" do
        s1 = "foo\nbar\nbang"
        s2 = "foo\nbar\nbangleize"
        expect(Diffy::Diff.new(s1,s2).to_s(:html)).to eq <<-DIFF
<div class="diff">
  <ul>
    <li class="unchanged"><span>foo</span></li>
    <li class="unchanged"><span>bar</span></li>
    <li class="del"><del>bang</del></li>
    <li class="ins"><ins>bang<strong>leize</strong></ins></li>
  </ul>
</div>
        DIFF
      end

      it "should correctly do inline hightlighting when default diff options are changed" do
        original_options = ::Diffy::Diff.default_options
        begin
              ::Diffy::Diff.default_options.merge!(:diff => '-U0')

              s1 = "foo\nbar\nbang"
              s2 = "foo\nbar\nbangleize"
              expect(Diffy::Diff.new(s1,s2).to_s(:html)).to eq <<-DIFF
<div class="diff">
  <ul>
    <li class="del"><del>bang</del></li>
    <li class="ins"><ins>bang<strong>leize</strong></ins></li>
  </ul>
</div>
        DIFF
        ensure
          ::Diffy::Diff.default_options = original_options
        end
      end
    end

    it "should escape diffed html in html output" do
      diff = Diffy::Diff.new("<script>alert('bar')</script>", "<script>alert('foo')</script>").to_s(:html)
      expect(diff).to include('&lt;script&gt;')
      expect(diff).not_to include('<script>')
    end

    it "should be easy to generate custom format" do
      expect(Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").map do |line|
        case line
        when /^\+/ then "line #{line.chomp} added"
        when /^-/ then "line #{line.chomp} removed"
        end
      end.compact.join).to eq("line +baz added")
    end

    it "should let you iterate over chunks instead of lines" do
      expect(Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each_chunk.map do |chunk|
        chunk
      end).to eq([" foo\n bar\n", "+baz\n"])
    end

    it "should allow chaining enumerable methods" do
      expect(Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each.map do |line|
        line
      end).to eq([" foo\n", " bar\n", "+baz\n"])
    end
  end
end

describe Diffy::SplitDiff do
  before do
    ::Diffy::Diff.default_options.merge!(:diff => '-U 10000')
  end

  it "should fail with invalid format" do
    expected_fail = expect do
      Diffy::SplitDiff.new("lorem\n", "ipsum\n", :format => :fail)
    end
    expected_fail.to raise_error(ArgumentError)
  end

  describe "#left" do
    it "should only highlight deletions" do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(Diffy::SplitDiff.new(string1, string2).left).to eq <<-TEXT
 lorem
-ipsum
-dolor
 sit amet
      TEXT
    end

    it "should also format left diff as html" do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(Diffy::SplitDiff.new(string1, string2, :format => :html).left).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>lorem</span></li>
    <li class="del"><del>ipsum<strong></strong></del></li>
    <li class="del"><del><strong></strong>dolor</del></li>
    <li class="unchanged"><span>sit amet</span></li>
  </ul>
</div>
      HTML
    end
  end

  describe "#right" do
    it "should only highlight insertions" do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(Diffy::SplitDiff.new(string1, string2).right).to eq <<-TEXT
 lorem
+ipsumdolor
 sit amet
      TEXT
    end

    it "should also format right diff as html" do
      string1 = "lorem\nipsum\ndolor\nsit amet\n"
      string2 = "lorem\nipsumdolor\nsit amet\n"
      expect(Diffy::SplitDiff.new(string1, string2, :format => :html).right).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>lorem</span></li>
    <li class="ins"><ins>ipsumdolor</ins></li>
    <li class="unchanged"><span>sit amet</span></li>
  </ul>
</div>
      HTML
    end
  end
end

describe 'Diffy::CSS' do
  it "should be some css" do
    expect(Diffy::CSS).to include 'diff{overflow:auto;}'
  end
end

