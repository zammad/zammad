var gulp = require('gulp');
var autoprefixer = require('gulp-autoprefixer');
const sass = require('gulp-sass')(require('sass'));
var gutil = require('gulp-util');
var concat = require('gulp-concat');
var coffee = require('gulp-coffee');
var eco = require('gulp-eco');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var merge = require('merge-stream');
var order = require("gulp-order");

function css(cb) {
  gulp.src('chat.scss')
    .pipe(sass.sync().on('error', gutil.log))
    .pipe(autoprefixer({
        cascade: false
    }))
    .pipe(gulp.dest('./'));
  cb();
}


function js(cb) {
  var templates = gulp.src('views/*.eco')
    .pipe(eco({namespace: 'zammadChatTemplates'}));

  var purify = gulp.src('purify.min.js');

  var js = gulp.src('chat.coffee')
    .pipe(coffee({bare: true}).on('error', gutil.log));

  merge(templates, purify, js)
    .pipe(order([
      "views/*.js",
      "purify.min.js",
      "chat.js",
    ], {base: './'}))
    .pipe(concat('chat.js'))
    .pipe(gulp.dest('./'))
    .pipe(uglify())
    .pipe(rename({ extname: '.min.js' }))
    .pipe(gulp.dest('./'));

  cb();
}


function no_jquery(cb) {
  var templates = gulp.src('views/*.eco')
    .pipe(eco({namespace: 'zammadChatTemplates'}));

  var purify = gulp.src('purify.min.js');

  var js = gulp.src('chat-no-jquery.coffee')
    .pipe(coffee({bare: true}).on('error', gutil.log));

  merge(templates, purify, js)
    .pipe(order([
      "views/*.js",
      "purify.min.js",
      "chat.js",
    ], {base: './'}))
    .pipe(concat('chat-no-jquery.js'))
    .pipe(gulp.dest('./'))
    .pipe(uglify())
    .pipe(rename({ extname: '.min.js' }))
    .pipe(gulp.dest('./'));

  cb();
}

exports.default = function() {
  gulp.watch(['chat.scss'], css);
  gulp.watch(['chat.coffee', 'views/*.eco'], js);
  gulp.watch(['chat-no-jquery.coffee', 'views/*.eco'], no_jquery);
}

exports.build = gulp.parallel(js, no_jquery, css)
