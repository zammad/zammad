# coffeelint: disable=camel_case_classes
class App.UiElement.richtext.toolButtons.link extends App.UiElement.richtext.additions.RichTextToolButtonLink
  @icon: 'chain'
  @text: 'Weblink'
  @klass: -> App.UiElement.richtext.additions.RichTextToolPopupLink
  @initializeAttributes:
    model:
      configure_attributes: [
        {
          name: 'link'
          display: 'Link'
          tag: 'input'
          placeholder: 'http://'
        }
      ]
