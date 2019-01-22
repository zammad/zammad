var gulp = require('gulp');
var autoprefixer = require('gulp-autoprefixer');
var sass = require('gulp-sass');
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var eco = require('gulp-eco');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var merge = require('merge-stream');
var plumber = require('gulp-plumber');

gulp.task('css', function(){
  return gulp.src('chat.scss')
    .pipe(sass.sync().on('error', gutil.log))
    .pipe(autoprefixer({
        browsers: ['last 4 versions'],
        cascade: false
    }))
    .pipe(gulp.dest('./'));
});


gulp.task('js', function(){
  var templates = gulp.src('views/*.eco')
    .pipe(eco({namespace: 'zammadChatTemplates'}));

  var js = gulp.src('chat.coffee')
    .pipe(plumber())
    .pipe(coffee({bare: true}).on('error', gutil.log));

  return merge(templates, js)
    .pipe(concat('chat.js'))
    .pipe(gulp.dest('./'))
    .pipe(uglify())
    .pipe(rename({ extname: '.min.js' }))
    .pipe(gulp.dest('./'));
});


gulp.task('no-jquery', function(){
  var templates = gulp.src('views/*.eco')
    .pipe(eco({namespace: 'zammadChatTemplates'}));

  var js = gulp.src('chat-no-jquery.coffee')
    .pipe(plumber())
    .pipe(coffee({bare: true}).on('error', gutil.log));

  return merge(templates, js)
    .pipe(concat('chat-no-jquery.js'))
    .pipe(gulp.dest('./'))
    .pipe(uglify())
    .pipe(rename({ extname: '.min.js' }))
    .pipe(gulp.dest('./'));
});

gulp.task('default', function(){
  var cssWatcher = gulp.watch(['chat.scss'], ['css']);
  cssWatcher.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });

  var jsWatcher = gulp.watch(['chat.coffee', 'views/*.eco'], ['js']);
  jsWatcher.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });

  var js2Watcher = gulp.watch(['chat-no-jquery.coffee'], ['no-jquery']);
  js2Watcher.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });
});
