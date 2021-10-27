'use strict';

/**
* @name: SKU
* @description: Maintains SKU data
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
  this.app.factory('Sku', ['$http', '$q', function($http, $q) {
    return {
      by_client: function(type) {
        var defer = $q.defer();
        $http({
          url: '/skus/by_client',
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
      new: function() {
        return { 'sku': { 'name': '', 'amount': 0, 'min_amount': 0, 'description': '', warehouse_id: 0 } };
      },

      updateMinStock: function(skus) {
        var defer = $q.defer();
        $http({
          url: '/skus/update_min_stock',
          method: 'POST',
          data: {
            skus: skus
          }
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
