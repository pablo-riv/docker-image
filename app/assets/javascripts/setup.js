// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require tether
//= require bootstrap-sprockets
//= require jquery_ujs
//= require turbolinks
//= require devise
//= require select2
//= require underscore/underscore-min
//= require ladda/dist/spin.min
//= require ladda/dist/ladda.min
//= require Chart.bundle
//= require chartkick

//= require angular/angular.min
//= require angular-animate/angular-animate.min
//= require angular-resource/angular-resource.min
//= require angular-bootstrap/ui-bootstrap
//= require angular-bootstrap/ui-bootstrap-tpls
//= require inflection/inflection.min
//= require ngInflection/dist/ngInflection.min
//= require ng-tags-input/ng-tags-input
//= require angular-loading-bar/src/loading-bar
//= require angular-ladda/dist/angular-ladda
//= require angular-sanitize/angular-sanitize.min
//= require ngDraggable/ngDraggable
//= require ngstorage/ngStorage.min
//= require angular-rut/dist/angular-rut.min
//= require trix/dist/trix
//= require angular-trix/dist/angular-trix.min


//= require app/app
//= require_tree ./app/config
//= require_tree ./app/controllers
//= require_tree ./app/models
//= require_tree ./app/filters
//= require_tree ./app/services

$(document).on("turbolinks:load", function () {

  window.dataLayer = window.dataLayer || [];
  function gtag() { dataLayer.push(arguments); }
  gtag('js', new Date());
  gtag('config', 'UA-136725524-1');

});