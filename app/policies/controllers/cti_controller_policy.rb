class Controllers::CtiControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('cti.agent')
end
