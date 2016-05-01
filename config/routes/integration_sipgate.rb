Zammad::Application.routes.draw do

  match '/api/v1/sipgate/in',     to: 'integration/sipgate#in',    via: :post
  match '/api/v1/sipgate/out',    to: 'integration/sipgate#out',   via: :post

end
