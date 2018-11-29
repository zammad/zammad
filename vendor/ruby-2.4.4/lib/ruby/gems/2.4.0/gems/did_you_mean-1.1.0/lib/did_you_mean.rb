require "did_you_mean/version"
require "did_you_mean/core_ext/name_error"

require "did_you_mean/spell_checker"
require 'did_you_mean/spell_checkers/name_error_checkers'
require 'did_you_mean/spell_checkers/method_name_checker'
require 'did_you_mean/spell_checkers/null_checker'

require "did_you_mean/formatter"

module DidYouMean
  IGNORED_CALLERS = []

  SPELL_CHECKERS = Hash.new(NullChecker)
  SPELL_CHECKERS.merge!({
    "NameError"     => NameErrorCheckers,
    "NoMethodError" => MethodNameChecker
  })
end
