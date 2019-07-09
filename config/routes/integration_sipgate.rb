Zammad::Application.routes.draw do

  match '/api/v1/sipgate/in',     to: 'integration/sipgate#event',    via: :post
  match '/api/v1/sipgate/out',    to: 'integration/sipgate#event',   via: :post

end
