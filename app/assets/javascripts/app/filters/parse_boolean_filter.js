'use strict';
(function () {
  this.app.filter('parseBoolean', function () {
    return function (param) {
      switch (typeof param) {
        case 'string':
          if (param.toLowerCase() == 'no') {
            return false;
          } else {
            return true;
          }
          break;
        default:
          if (param) {
            return 'Si';
          } else {
            return 'No';
          }
          break;
      }
    };
  });
}).call(this);