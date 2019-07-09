class Cti::Driver::Cti < Cti::Driver::Base

  def config
    Setting.get('cti_config')
  end

end
