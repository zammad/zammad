var gulp = require('gulp');
var gutil = require('gulp-util');
var rename = require('gulp-rename');
var svgstore = require('gulp-svgstore');
var svgmin = require('gulp-svgmin');
var cheerio = require('cheerio');
var gcheerio = require('gulp-cheerio');
var through2 = require('through2');
var path = require('path');

var iconsource = 'icons/*.svg'

function build(cb) {
  gulp
    .src(iconsource)
    .pipe(rename({prefix: 'icon-'}))
    .pipe(svgmin(function getOptions(file){
      var prefix = path.basename(
        file.relative,
        path.extname(file.relative)
      );
      return {
        plugins: [
          {
            removeViewBox: false,
            removeTitle: false,
            cleanupIDs: {
              prefix: prefix + '-',
              minify: true
            }
          },
        ],
        js2svg: {
          pretty: true,
        },
      }
    }))
    .pipe(gcheerio({
      run: function ($) {
          // remove green-screen color
          $('[fill="#50E3C2"]').removeAttr('fill').parents('[fill="none"]').removeAttr('fill');
          $('[fill="#BD0FE1"]').attr('fill', 'currentColor').parents('[fill="none"]').removeAttr('fill');
          // color in Sketch changed slightly BD0FE1 -> BD10E0
          $('[fill="#BD10E0"]').attr('fill', 'currentColor').parents('[fill="none"]').removeAttr('fill');
      },
      parserOptions: { xmlMode: true }
    }))
    .pipe(svgstore())
    .pipe(through2.obj(function (file, encoding, cb) {
      // Side effect: generate app/assets/stylesheets/svg-dimensions.css with
      //  information about the available icon sizes.
      var $ = cheerio.load(file.contents)
      var data = $('svg > symbol').map(function (_i, tag) {
        var viewBox = tag.attribs.viewbox.split(" ")
        return [
          '.'+ $(this).attr('id') + ' {' +
            ' width: ' + viewBox[2] + 'px;' +
            ' height: ' + viewBox[3] + 'px; ' +
          '}'
        ];
      }).get();
      var cssFile = new gutil.File({
          path: '../../../app/assets/stylesheets/svg-dimensions.css',
          contents: Buffer.from(data.join("\n"))
      });
      this.push(cssFile);
      this.push(file);
      cb();
    }))
    .pipe(gulp.dest('./'));
  cb();
}

exports.default = function(cb) {
  gulp.watch(iconsource, build);
  cb();
}
exports.build = build
