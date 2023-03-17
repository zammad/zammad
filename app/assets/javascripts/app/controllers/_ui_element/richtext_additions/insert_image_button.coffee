# coffeelint: disable=camel_case_classes
class App.UiElement.richtext.toolButtons.insert_image extends App.UiElement.richtext.additions.RichTextToolButton
  @icon: 'web'
  @text: __('Image')
  @klass: -> App.UiElement.richtext.additions.RichTextToolPopupImage
  @initializeAttributes:
    model:
      configure_attributes: [
        {
          name: 'link'
          display: __('Image')
          tag: 'input'
          type: 'file'
        }
      ]

  @pickExisting: (sel, textEditor) ->
    selectedImage = textEditor.find('img.objectResizingEditorActive')[0]
