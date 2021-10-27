'use strict';

/**
* @name: COMPANY
* @description: Maintains COMPANY data
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
  this.app.factory('Company', ['$http', '$q', function ($http, $q) {
    return {
      setup: function(data) {
        var defer = $q.defer();
        $http({
          url: '/setup/company',
          method: 'PATCH',
          data: {
            company: data
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      updateEmailPreference: function(company) {
        var defer = $q.defer();
        $http({
          url: 'companies/update_preference',
          method: 'PUT',
          data: {
            company: company
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      // fulfillment: function() {
      //   var defer = $q.defer();
      //   $http({
      //     url: '/administration/companies/all_fulfillment',
      //     method: 'GET',
      //   }).then(function(model) {
      //     defer.resolve(model.data);
      //   }, function(model) {
      //     defer.reject(model.data);
      //   });
      //   return defer.promise;
      // },
      //
      // all: function() {
      //   var defer = $q.defer();
      //   $http({
      //     url: '/administration/companies/all',
      //     method: 'GET',
      //   }).then(function(model) {
      //     defer.resolve(model.data);
      //   }, function(model) {
      //     defer.reject(model.data);
      //   });
      //   return defer.promise;
      // },

      serviceName: function(name) {
        switch (name) {
          case 'opit':
            name = 'Opit';
            break;
          case 'fullit':
            name = 'Integraciones';
            break;
          case 'pp':
            name = 'Pick & Pack';
            break;
          case 'fulfillment':
            name = 'Fulfillment';
            break;
          case 'sd':
            name = 'Shipit Delivery';
            break;
          default:
            name = 'Error';
            break;
        }
        return name;
      }

    };
  }]);
}).call(this);
