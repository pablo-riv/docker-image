'use strict';
(function() {
  this.app.factory('Analytics', ['$q', '$http', function($q, $http) {
    return {
      getData: function(search){
        var defer = $q.defer();
        $http({
          url: '/analytics/search',
          method: 'GET',
          params: {
            dates: search
          }
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