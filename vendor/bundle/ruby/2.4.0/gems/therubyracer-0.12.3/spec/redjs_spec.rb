require 'spec_helper'
require 'redjs/load_specs'
module RedJS
  Context = V8::Context
  Error = V8::Error
end
describe V8::Context do
  skip "not ready for prime-time"
  #it_behaves_like 'RedJS::Context'
end
