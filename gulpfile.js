var gulp    = require('gulp');
var coffee  = require('gulp-coffee');
var concat  = require('gulp-concat');
var replace = require('gulp-replace');

gulp.task('coffee', function() {
  gulp.src('./src/coffee/*.coffee')
    .pipe(concat('app.coffee'))
    .pipe(coffee({bare: true}))
    .pipe(replace(/module\.exports = \w+;/g, ''))
    .pipe(replace(/\w+ = require\('\.\/\w+'\);/g, ''))
    .pipe(gulp.dest('./src/js/'));
});

gulp.task('default', ['coffee']);
