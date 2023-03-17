# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

if !Rails.env.production?
  Zammad::Application.routes.draw do
    get '/tests_:name', to: 'tests#show'

    match '/tests/wait/:sec',        to: 'tests#wait',                   via: :get
    match '/tests/raised_exception', to: 'tests#error_raised_exception', via: :get

    # user agent tests
    match 'test/get/:sec',          to: 'user_agent_test#get',      via: %i[get options]
    match 'test/get_accepted/:sec', to: 'user_agent_test#accepted', via: :get
    match 'test/redirect',          to: 'user_agent_test#redirect', via: :get
    match 'test/post/:sec',         to: 'user_agent_test#post',     via: :post
    match 'test/put/:sec',          to: 'user_agent_test#put',      via: :put
    match 'test/delete/:sec',       to: 'user_agent_test#delete',   via: :delete

    # user agent tests with basic auth
    match 'test_basic_auth/get/:sec',    to: 'user_agent_test_basic_auth#get',      via: %i[get options]
    match 'test_basic_auth/post/:sec',   to: 'user_agent_test_basic_auth#post',     via: :post
    match 'test_basic_auth/put/:sec',    to: 'user_agent_test_basic_auth#put',      via: :put
    match 'test_basic_auth/delete/:sec', to: 'user_agent_test_basic_auth#delete',   via: :delete
    match 'test_basic_auth/redirect',    to: 'user_agent_test_basic_auth#redirect', via: :get
  end
end
