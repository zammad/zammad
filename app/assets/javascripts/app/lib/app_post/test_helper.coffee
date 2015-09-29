class App.TestHelper
  @attachmentUploadFake: ( selector ) ->

    fileTemplate = '''<div class="attachment horizontal">
  <div class="attachment-name u-highlight">fake.file</div>
  <div class="attachment-size">30 KB</div>
  <div class="attachment-delete js-delete align-right u-clickable" data-id="33009">
    <div class="delete icon"></div>Delete File
  </div>
</div>'''
    $(selector).append(fileTemplate)
