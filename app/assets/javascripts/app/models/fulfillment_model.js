'use strict';

/**
* @name:Fulfillment
* @description: Maintains Fulfillment data
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
  this.app.factory('Fulfillment', ['$http', '$q', function ($http, $q) {
    return {

      history: function(inventoryType, page) {
        var defer = $q.defer();
        $http({
          url: 'history',
          method: 'GET',
          params:{
            inventory_activity_type_ids: [inventoryType],
            page: page
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      timeline: function(type, id, page){
        var defer = $q.defer();
        $http({
          url: 'timelines',
          method: 'GET',
          params:{
            type: type,
            id: id,
            page: page
          }
        }).then(function(model){
          defer.resolve(model.data);
        }, function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      }


    };
  }]);
}).call(this);
