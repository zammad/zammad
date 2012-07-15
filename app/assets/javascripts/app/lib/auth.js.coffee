$ = jQuery.sub()

class App.Auth

  @login: (params) ->
    console.log 'login(...)', params
    App.Com.ajax(
      id:     'login',
#      params,
      type:   'POST',
      url:     '/signin',
      data:    JSON.stringify(params.data),
      success: params.success,
      error:   params.error,
    )

  @loginCheck: ->
    console.log 'loginCheck(...)'
    App.Com.ajax(
      id:    'login_check',
      async: false,
      type:  'GET',
      url:   '/signshow',
      success: (data, status, xhr) =>
        console.log 'logincheck:success', data

        # if session is not valid
        if data.error
  
          # update config
          for key, value of data.config
            window.Config[key] = value

          # empty session
          window.Session = {}

          # rebuild navbar with new navbar items
          Spine.trigger 'navrebuild'

          return false;

        # set avatar
        if !data.session.image
          data.session.image = 'http://placehold.it/48x48'

        # update config
        for key, value of data.config
          window.Config[key] = value

        # store user data
        for key, value of data.session
          window.Session[key] = value
    
        # refresh/load default collections
        for key, value of data.default_collections
          App[key].refresh( value, options: { clear: true } )

        # rebuild navbar with new navbar items
        Spine.trigger 'navrebuild', data.session
    
        # rebuild navbar with updated ticket count of overviews
        Spine.trigger 'navupdate_remote'


      error: (xhr, statusText, error) =>
        console.log 'loginCheck:error'#, error, statusText, xhr.statusCode
       
        # empty session
        window.Session = {}
    )

  @logout: ->
    console.log 'logout(...)'
    App.Com.ajax(
      id:   'logout',
      type: 'DELETE',
      url:  '/signout',
    )