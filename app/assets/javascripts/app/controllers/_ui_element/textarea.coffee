# coffeelint: disable=camel_case_classes
class App.UiElement.textarea
  @render: (attribute) ->

    # set an appropriate default value for rows, if not given
    if attribute.rows is undefined
      attribute.rows = 4

    item = $( App.view('generic/textarea')( attribute: attribute ) )

    if attribute.collapsible
      collapseClasses= 'panel-collapse collapse'
      if !_.isEmpty(attribute.value)
        collapseClasses += ' in'
      item = $('<div id="collapse-' + attribute.id + '" class="' + collapseClasses + '">').append(item)

    if attribute.upload
      fileUploaderId = 'file-uploader-' + new Date().getTime() + '-' + Math.floor( Math.random() * 99999 )
      item.append('<div class="file-uploader ' + attribute.class + '" id="' + fileUploaderId + '"></div>')

      # add file uploader
      u = ->

        # only add upload item if html element exists
        if $('#' + fileUploaderId )[0]
          form_id = item.closest('form').find('[name=form_id]').val()
          $('#' + fileUploaderId ).fineUploader(
            request:
              endpoint: "#{App.Config.get('api_path')}/upload_caches/#{form_id}"
            text:
              uploadButton: App.Utils.icon('paperclip')
            template: '<div class="qq-uploader">' +
                        '<pre class="btn qq-upload-icon qq-upload-drop-area"><span>{dragZoneText}</span></pre>' +
                        '<div class="btn btn-default qq-upload-icon2 qq-upload-button pull-right" style="">{uploadButtonText}</div>' +
                        '<ul class="qq-upload-list span5" style="margin-top: 10px;"></ul>' +
                      '</div>',
            customHeaders:
              'X-CSRF-Token': App.Ajax.token()
            classes:
              success: ''
              fail:    ''
            debug: false
          )
      App.Delay.set(u, 100, undefined, 'form_upload')
    item
