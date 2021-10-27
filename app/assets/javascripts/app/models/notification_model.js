'use strict';

/**
* @name: Notification
* @description: Maintains Notification data
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
  this.app.factory('Notification', ['$q', '$http', '$uibModal', function($q, $http, $uibModal) {
    return {
      findBy: function(companyId) {
        var defer = $q.defer();
        $http({
          url: 'notifications/by_company',
          params: {
            company_id: companyId
          },
          method: 'GET'
        }).then(function(model){
          defer.resolve(model.data);
        }, function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      },

      update: function(data){
        var defer = $q.defer();
        $http({
          url: 'notifications/single_update',
          method: 'PUT',
          data: {
            setting: data
          }
        }).then(function(model){
          defer.resolve(model.data);
        },function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      },

      skusModal: function(skus) {
        var modal = $uibModal.open({
          animation: true,
          templateUrl: 'security_stock.html',
          controller: 'SecurityStockController',
          size: 'lg',
          resolve: {
            skus: function() {
              return skus;
            }
          }
        });
        modal.result.then(function() {
        }, function(error) {
        });
      },

      baseFormatModal: function(company) {
        var defer = $q.defer();
        var modal = $uibModal.open({
          animation: true,
          templateUrl: 'base_format.html',
          controller: 'EmailBaseFormatController',
          size: 'lg',
          resolve: {
            company: function() {
              return company;
            }
          }
        });
        modal.result.then(function(company) {
          defer.resolve(company);
        }, function(error) {
          defer.reject(error);
        });
        return defer.promise;
      }

    };
  }]);
}).call(this);
