module Viewpoint::EWS::Types
  class Message
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::Item
  end
end
