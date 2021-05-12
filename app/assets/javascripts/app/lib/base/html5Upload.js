/*jslint unparam: true, browser: true, devel: true */
/*global define*/


    var module = {},
        noop = function () { },
        console = window.console || { log: noop },
        supportsFileApi;

    // Upload manager constructor:
    function UploadManager(options) {
        var self = this;
        self.dropContainer = options.dropContainer;
        self.inputField = options.inputField;
        self.cancelContainer = options.cancelContainer;
        self.uploadsQueue = [];
        self._xhrs = [];
        self.activeUploads = 0;
        self.data = options.data;
        self.key = options.key;
        self.maxSimultaneousUploads = options.maxSimultaneousUploads || -1;
        self.onFileAdded = options.onFileAdded || noop;
        self.uploadUrl = options.uploadUrl;
        self.onFileAddedProxy = function (upload) {
            console.log('Event: onFileAdded, file: ' + upload.fileName);
            self.onFileAdded(upload);
        };

        self.initialize();
    }

    // FileUpload proxy class:
    function FileUpload(file) {
        var self = this;

        self.file = file;
        self.fileName = file.name;
        self.fileSize = file.size;
        self.uploadSize = file.size;
        self.uploadedBytes = 0;
        self.eventHandlers = {};
        self.events = {
            onProgress: function (fileSize, uploadedBytes) {
                var progress = uploadedBytes / fileSize * 100;
                console.log('Event: upload onProgress, progress = ' + progress + ', fileSize = ' + fileSize + ', uploadedBytes = ' + uploadedBytes);
                (self.eventHandlers.onProgress || noop)(progress, fileSize, uploadedBytes);
            },
            onStart: function () {
                console.log('Event: upload onStart');
                (self.eventHandlers.onStart || noop)();
            },
            onAborted: function () {
                console.log('Event: upload onAborted');
                (self.eventHandlers.onAborted || noop)();
            },
            onCompleted: function (data) {
                console.log('Event: upload onCompleted, data = ' + data);
                file = null;
                (self.eventHandlers.onCompleted || noop)(data);
            },
            onError: function (message) {
                console.log('Event: upload error, message: ' + message);
                (self.eventHandlers.onError || noop)(message);
            }
        };
    }

    FileUpload.prototype = {
        on: function (eventHandlers) {
            this.eventHandlers = eventHandlers;
        }
    };

    UploadManager.prototype = {

        initialize: function () {
            //console.log('Initializing upload manager');
            var manager = this,
                dropContainer = manager.dropContainer,
                inputField = manager.inputField,
                cancelContainer = manager.cancelContainer,
                inCounter = 0,
                onDragEnter = function (e) {
                    e.preventDefault()
                    e.stopPropagation()
                    inCounter++
                    //console.log('in', inCounter, dropContainer)
                    showDropZone(dropContainer)
                };
                onDragOver = function (e) {
                    e.dataTransfer.dropEffect = 'copy';
                    e.preventDefault()
                    e.stopPropagation()
                };
                onDragLeave = function (e) {
                    e.preventDefault()
                    e.stopPropagation()
                    inCounter--
                    //console.log('out', inCounter)
                    if ( inCounter == 0 ) {
                      hideDropZone(dropContainer)
                    }
                };
                onDrop = function (e) {
                    inCounter = 0
                    onDragEnter(e);
                    hideDropZone(dropContainer)
                    manager.processFiles(e.dataTransfer.files)
                };
                showDropZone = function(dropContainer) {
                  $(dropContainer).trigger('html5Upload.dropZone.show')

                  if ( !$(dropContainer).find('.article-content, .richtext').hasClass('is-dropTarget') ) {
                    $(dropContainer).find('.article-content, .richtext').addClass('is-dropTarget')
                  }
                }
                hideDropZone = function(dropContainer) {
                  $(dropContainer).trigger('html5Upload.dropZone.hide')

                  if ( $(dropContainer).find('.article-content, .richtext').hasClass('is-dropTarget') ) {
                    $(dropContainer).find('.article-content, .richtext').removeClass('is-dropTarget')
                  }
                }

            if (dropContainer) {
                manager.on(dropContainer, 'dragleave', onDragLeave)
                manager.on(dropContainer, 'dragover', onDragOver)
                manager.on(dropContainer, 'dragenter', onDragEnter)
                manager.on(dropContainer, 'drop', onDrop)
            }

            if (inputField) {
                manager.on(inputField, 'change', function () {
                    manager.processFiles(this.files);
                });
            }

            if (cancelContainer) {
                cancelContainer.on('click', function() {
                    manager.uploadCancel()
                })
            }
        },

        processFiles: function (files) {
            console.log('Processing files: ' + files.length);
            var manager = this,
                len = files.length,
                file,
                upload,
                i;

            for (i = 0; i < len; i += 1) {
                file = files[i];
                if (file.size === 0) {
                    alert('Files with files size zero cannot be uploaded or multiple file uploads are not supported by your browser');
                    break;
                }

                upload = new FileUpload(file);
                manager.uploadFile(upload);
            }
        },

        uploadCancel: function () {
          var manager = this;
          //manager.uploadsQueue.shift()
          _.each( manager._xhrs, function(xhr){
            xhr.abort()
          })
          manager._xhrs = []
        },

        uploadFile: function (upload) {
            var manager = this;

            manager.onFileAdded(upload);

            // Queue upload if maximum simultaneous uploads reached:
            if (manager.activeUploads === manager.maxSimultaneousUploads) {
                console.log('Queue upload: ' + upload.fileName);
                manager.uploadsQueue.push(upload);
                return;
            }

            manager.ajaxUpload(upload);
        },

        ajaxUpload: function (upload) {
            var manager = this,
                xhr,
                formData,
                fileName,
                file = upload.file,
                prop,
                data = manager.data,
                key = manager.key || 'file';

            console.log('Beging upload: ' + upload.fileName);
            manager.activeUploads += 1;

            xhr = new window.XMLHttpRequest();
            manager._xhrs.push( xhr )
            formData = new window.FormData();
            fileName = file.name;

            xhr.open('POST', manager.uploadUrl);

            // add csrf token
            if (App.Ajax && App.Ajax.token) {
              xhr.setRequestHeader('X-CSRF-Token', App.Ajax.token());
            }

            // Triggered when upload starts:
            xhr.upload.onloadstart = function () {
                // File size is not reported during start!
                console.log('Upload started: ' + fileName);
                upload.events.onStart();
            };

            // Triggered many times during upload:
            xhr.upload.onprogress = function (event) {
                if (!event.lengthComputable) {
                    return;
                }

                // Update file size because it might be bigger than reported by the fileSize:
                upload.events.onProgress(event.total, event.loaded);
            };

            // Triggered when upload is completed:
            xhr.onload = function (event) {
                // Reduce number of active uploads:
                manager.activeUploads -= 1;

                // call the error callback when the status is not ok
                if (xhr.status !== 200){
                  console.log('Upload failed: ' + fileName);
                  upload.events.onError(event.target.statusText);
                } else {
                  console.log('Upload completed: ' + fileName);
                  upload.events.onCompleted(event.target.responseText);
                }

                // Check if there are any uploads left in a queue:
                if (manager.uploadsQueue.length) {
                    manager.ajaxUpload(manager.uploadsQueue.shift());
                }
            };
            xhr.abort = function (event) {
                console.log('Upload abort');

                // Reduce number of active uploads:
                manager.activeUploads -= 1;

                upload.events.onAborted();

                manager.uploadsQueue = []
            }

            // Triggered when upload fails:
            xhr.onerror = function () {
                console.log('Upload failed: ', upload.fileName);
            };

            // Append additional data if provided:
            if (data) {
                for (prop in data) {
                    if (data.hasOwnProperty(prop)) {
                        console.log('Adding data: ' + prop + ' = ' + data[prop]);
                        formData.append(prop, data[prop]);
                    }
                }
            }

            // Append file data:
            formData.append(key, file);

            // Initiate upload:
            xhr.send(formData);
        },

        // Event handlers:
        on: function (element, eventName, handler) {
            if (!element) {
                return;
            }
            if (element.addEventListener) {
                element.addEventListener(eventName, handler, false);
            } else if (element.attachEvent) {
                element.attachEvent('on' + eventName, handler);
            } else {
                element['on' + eventName] = handler;
            }
        }
    };

    module.fileApiSupported = function () {
        if (typeof supportsFileApi !== 'boolean') {
            var input = document.createElement("input");
            input.setAttribute("type", "file");
            supportsFileApi = !!input.files;
        }

        return supportsFileApi;
    };

    module.initialize = function (options) {
        return new UploadManager(options);
    };

    window.html5Upload = module;
