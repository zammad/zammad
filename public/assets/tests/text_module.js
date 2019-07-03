// text module
test('test text module behaviour with group_ids', function() {

  // active textmodule without group_ids
  App.TextModule.refresh([
    {
      id:       1,
      name:     'main',
      keywords: 'keywordsmain',
      content:  'contentmain',
      active:   true,
    },
    {
      id:       2,
      name:     'test2',
      keywords: 'keywords2',
      content:  'content2',
      active:   false,
    },
    {
      id:        3,
      name:      'test3',
      keywords:  'keywords3',
      content:   'content3',
      active:    true,
      group_ids: [1,2],
    },
    {
      id:        4,
      name:      'test4',
      keywords:  'keywords4',
      content:   'content4',
      active:    false,
      group_ids: [1,2],
    },
  ])

  var textModule = new App.WidgetTextModule({
      el: $('.js-textarea').parent(),
      data:{
        user:   App.Session.get(),
        config: App.Config.all(),
      },
      taskKey: 'test1',
  })

  var currentCollection = textModule.currentCollection();

  equal(currentCollection.length, 2, 'active textmodule')
  equal(currentCollection[0].id, 1)
  equal(currentCollection[1].id, 3)

  // trigered TextModulePreconditionUpdate with group_id

  var params = {
    group_id: 1
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test1', params: params })

  currentCollection = textModule.currentCollection();

  equal(currentCollection.length, 2, 'trigered TextModulePreconditionUpdate with group_id')
  equal(currentCollection[0].id, 1)
  equal(currentCollection[1].id, 3)

  // trigered TextModulePreconditionUpdate with wrong group_id

  params = {
    group_id: 3
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test1', params: params })

  currentCollection = textModule.currentCollection();

  equal(currentCollection.length, 1, 'trigered TextModulePreconditionUpdate with wrong group_id')
  equal(currentCollection[0].id, 1)

  // trigered TextModulePreconditionUpdate with group_id but wrong taskKey

  params = {
    group_id: 3
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test2', params: params })

  currentCollection = textModule.currentCollection();

  equal(currentCollection.length, 1, 'trigered TextModulePreconditionUpdate with group_id but wrong taskKey - nothing has changed')
  equal(currentCollection[0].id, 1)

  // trigered TextModulePreconditionUpdate without group_id

  params = {
    owner_id: 2
  }
  App.Event.trigger('TextModulePreconditionUpdate', { taskKey: 'test1', params: params })

  currentCollection = textModule.currentCollection();

  equal(currentCollection.length, 2, 'trigered TextModulePreconditionUpdate without group_id')
  equal(currentCollection[0].id, 1)
  equal(currentCollection[1].id, 3)

});
