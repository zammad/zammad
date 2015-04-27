class App.Locale extends App.Model
  @configure 'Locale', 'name', 'alias', 'locale'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/locales'