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
//= require jquery-ui
//= require tether
//= require bootstrap-sprockets
//= require jquery_ujs
//= require turbolinks
//= require_tree ./milestone-template/ui/
//= require milestone-template/constants
//= require milestone-template/main
//= require Chart.bundle
//= require chartkick
//= require tablefilter
//= require jquery.csv
//= require settings
//= require charges
//= require packages
//= require devise
//= require select2
//= require js-xlsx/dist/xlsx.full.min
//= require services
//= require underscore/underscore-min
//= require ladda/dist/spin.min
//= require ladda/dist/ladda.min
//= require bootstrap-colorpicker/dist/js/bootstrap-colorpicker
//= require bootstrap-datepicker.min
//= require bootstrap-datepicker.es.min

//= require angular/angular.min
//= require angular-i18n/angular-locale_es-cl.js
//= require angular-animate/angular-animate.min
//= require angular-resource/angular-resource.min
//= require angular-bootstrap/ui-bootstrap
//= require angular-bootstrap/ui-bootstrap-tpls
//= require inflection/inflection.min
//= require ngInflection/dist/ngInflection.min
//= require ng-tags-input/ng-tags-input
//= require angular-loading-bar/src/loading-bar
//= require angular-ladda/dist/angular-ladda
//= require angular-busy/dist/angular-busy
//= require angular-sanitize/angular-sanitize.min
//= require ngDraggable/ngDraggable
//= require ngstorage/ngStorage.min
//= require angular-rut/dist/angular-rut.min
//= require trix/dist/trix
//= require angular-trix/dist/angular-trix.min

//= require action_cable
//= require_tree ./channels

//= require app/app
//= require_tree ./app/config
//= require_tree ./app/controllers
//= require_tree ./app/models
//= require_tree ./app/filters
//= require_tree ./app/services
//= require_tree ./app/directives

Array.prototype.containsByProp = function(propName, value) {
  for (var i = this.length - 1; i > -1; i--) {
    var propObj = this[i];
    if (propObj[propName] === value) {
      return { sku: propObj, result: true };
    };
  };
  return { sku: {}, result: false };
};

String.prototype.capitalize = function() {
  return this.replace(/(?:^|\s)\S/g, function(a) { return a.toUpperCase(); });
};

String.prototype.titleize = function() {
  var arr = this.split(' ');
  arr = arr.map(function(str) { return str.capitalize(); });
  return arr.join(' ');
};

window.paceOptions = {
  document: true,
  eventLag: true,
  restartOnPushState: true,
  restartOnRequestAfter: true,
  ajax: {
    trackMethods: ['POST', 'GET']
  }
};

$(document).on("turbolinks:load", function() {

  window.dataLayer = window.dataLayer || [];
  function gtag() { dataLayer.push(arguments); }
  gtag('js', new Date());
  gtag('config', 'UA-136725524-1');

  Chartkick.configure({ language: 'es' });
  $('[data-toggle="tooltip"]').tooltip();

  if ($('.alert-strong').text().length > 0) {
    $('.alert-error').removeClass('hidden');
  } else if ($('.notice-strong').text().length > 0) {
    $('.notice-error').removeClass('hidden');
  };

  $('#company').select2();
  $('#company').on('change', function () {
    this.form.submit();
  });

  function readURL(input) {
    if (input.files && input.files[0]) {
      var reader = new FileReader();
      reader.onload = function (e) {
        $('.image-preview').css('background-image', 'url(' + e.target.result + ')');
        $('.image-preview').hide();
        $('.image-preview').fadeIn(650);
      }
      reader.readAsDataURL(input.files[0]);
    }
  }
  $(".image-upload").change(function () {
    readURL(this);
  });

  setTimeout(function () {
    $(".image-upload").each(function (element) {
      readURL(element);
    })
  }, 1000);
});