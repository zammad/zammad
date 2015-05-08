var gulp = require('gulp');
var rename = require('gulp-rename');
var svgstore = require('gulp-svgstore');
var svgmin = require('gulp-svgmin');
var cheerio = require('gulp-cheerio');
var iconsource = 'public/assets/images/icons/*.svg'

gulp.task('svgstore', function () {
  return gulp
    .src(iconsource)
    .pipe(rename({prefix: 'icon-'}))
    .pipe(svgmin())
    .pipe(cheerio({
      run: function ($) {
          // remove green-screen color
          $('[fill="#50E3C2"]').removeAttr('fill');
          // remove fill=none (<g>'s have it)
          $('[fill="none"]').removeAttr('fill');
      },
      parserOptions: { xmlMode: true }
    }))
    .pipe(svgstore())
    .pipe(gulp.dest('public/assets/images'));
});

gulp.task('watch', function () {
  gulp.watch(iconsource, ['svgstore']);
});

gulp.task('default', ['svgstore', 'watch']);