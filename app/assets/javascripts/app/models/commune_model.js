'use strict';

/**
* @name: COMMUNE
* @description: Maintains COMMUNE data
* @attributes:
*
* | Name                  | Type           |
* |-----------------------|----------------|
* | @id                   | integer        |
* | @created_at           | datetime       |
* | @updated_at           | datetime       |
*
**/
(function() {
  this.app.factory('Commune', ['$http', '$q', function($http, $q) {
    return {
      all: function(type) {
        var defer = $q.defer();
        $http({
          url: '/branch_offices/communes',
          method: 'GET',
          params: {
            type: type
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      availableDestinies: function() {
        var defer = $q.defer();
        $http({
          url: '/v/communes/availible_commune_starken',
          method: 'GET'
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      }
    };
  }]);
}).call(this);
