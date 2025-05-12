// image service
QUnit.test('test image resizing with defined height', assert => {
  var done = assert.async()

  App.ImageService.resize(image_40x30, 'auto', 15, 1, 'image/png', 0.7, function(image, width, height) {
    assert.equal(width, 20)

    done()
  })
});

QUnit.test('test image resizing with a GIF', assert => {
  var done = assert.async()

  App.ImageService.resize(image_gif, 12, 12, 1, 'image/gif', 1, function(dataURI, width, height) {
    assert.ok(dataURI.startsWith('data:image/png;base64,'), 'resized into PNG')
    assert.equal(height, 12, 'resized height')
    assert.equal(width, 12, 'resized width')

    done()
  })
});

QUnit.test('test no image resizing with a GIF', assert => {
  var done = assert.async()

  App.ImageService.resize(image_gif, 1200, 'auto', 1, 'image/gif', 1, function(dataURI, width, height) {
    assert.equal(dataURI, image_gif, 'original data URI')
    assert.equal(height, 16, 'original height')
    assert.equal(width, 16, 'original width')

    done()
  })
});

var image_40x30 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACgAAAAeCAIAAADRv8uKAAAAAXNSR0IArs4c6QAAAAlwSFlzAAAuIwAALiMBeKU/dgAAA6ppVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IlhNUCBDb3JlIDUuNC4wIj4KICAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgICAgPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIKICAgICAgICAgICAgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyIKICAgICAgICAgICAgeG1sbnM6ZXhpZj0iaHR0cDovL25zLmFkb2JlLmNvbS9leGlmLzEuMC8iPgogICAgICAgICA8eG1wOk1vZGlmeURhdGU+MjAxOS0wNy0wOVQxMzowNzo5ODwveG1wOk1vZGlmeURhdGU+CiAgICAgICAgIDx4bXA6Q3JlYXRvclRvb2w+UGl4ZWxtYXRvciAzLjguNTwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICAgICA8dGlmZjpDb21wcmVzc2lvbj4wPC90aWZmOkNvbXByZXNzaW9uPgogICAgICAgICA8dGlmZjpSZXNvbHV0aW9uVW5pdD4yPC90aWZmOlJlc29sdXRpb25Vbml0PgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj4zMDA8L3RpZmY6WVJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOlhSZXNvbHV0aW9uPjMwMDwvdGlmZjpYUmVzb2x1dGlvbj4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjQwPC9leGlmOlBpeGVsWERpbWVuc2lvbj4KICAgICAgICAgPGV4aWY6Q29sb3JTcGFjZT4xPC9leGlmOkNvbG9yU3BhY2U+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4zMDwvZXhpZjpQaXhlbFlEaW1lbnNpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgqEC5leAAAAS0lEQVRIDe3SsQ0AIAwDQWD/nYNo3X9S8Onc2NIpu6rWxJ2J0bfpcJu81FJjAj4XRpvFUqcIlqXGaLNY6hTBstQYbRZLnSJY/o/6AhOiAzl4JlrsAAAAAElFTkSuQmCC'

var image_gif = 'data:image/gif;base64,R0lGODlhEAAQAJECAAAAAP///////wAAACH5BAEAAAIALAAAAAAQABAAAAIylI+pAt1rWpjzJTBTRTisHXlQAITQQTLimWKn0a5j6b6pypahjN675jtIKCTdwmE5FAAAOw=='
