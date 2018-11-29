require 'rubygems'
require 'sinatra'
require 'json'
require File.dirname(__FILE__) + '/../lib/diffy'

blk = proc do
  Diffy::Diff.default_options.merge! JSON.parse(params[:options]) rescue {}
  haml "- d = Diffy::Diff.new(params[:one].to_s, params[:two].to_s)\n%div= d.to_s(:html)\n%pre= d.to_s"
end
post '/', &blk
get '/', &blk
__END__

@@ layout
%html
  %head
    :css
      .diff{overflow:auto;}
      .diff ul{background:#fff;overflow:auto;font-size:13px;list-style:none;margin:0;padding:0;display:table;width:100%;}
      .diff del, .diff ins{display:block;text-decoration:none;}
      .diff li{padding:0; display:table-row;margin: 0;height:1em;}
      .diff li.ins{background:#dfd; color:#080}
      .diff li.del{background:#fee; color:#b00}
      .diff li:hover{background:#ffc}
      .diff del, .diff ins, .diff span{white-space:pre-wrap;font-family:courier;}
      .diff del strong{font-weight:normal;background:#fcc;}
      .diff ins strong{font-weight:normal;background:#9f9;}
      .diff li.diff-comment { display: none; }
      .diff li.diff-block-info { background: none repeat scroll 0 0 gray; }
    %body
      = yield
      %form{:action => '', :method => 'post'}
        %label JSON diff options
        %textarea{:name => 'options', :style => 'width:100%;height:250px;'}= params[:options]
        %label One
        %textarea{:name => 'one', :style => 'width:100%;height:250px;'}= params[:one]
        %br/
        %label Two
        %textarea{:name => 'two', :style => 'width:100%;height:250px;'}= params[:two]
        %br/
        %input{:type => 'submit'}
        %br/

@@ index
%div.title Hello world!!!!!

