'use strict';
(function() {
  this.app.factory('Negotiation', ['$q', '$http', function($q, $http) {
    return {
      show: function() {
        var defer = $q.defer();
        $http({
          url: '/negotiations/company',
          method: 'GET',
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      }
    };
  }])
}).call(this);
