require 'did_you_mean'

module DidYouMean
  TRACE = TracePoint.trace(:raise) do |tp|
    e = tp.raised_exception

    if SPELL_CHECKERS.include?(e.class.to_s) && !e.instance_variable_defined?(:@frame_binding)
      e.instance_variable_set(:@frame_binding, tp.binding)
    end
  end

  NameError.send(:attr, :frame_binding)
end

require 'did_you_mean/experimental/initializer_name_correction'
require 'did_you_mean/experimental/ivar_name_correction'
require 'did_you_mean/experimental/key_error_name_correction'
