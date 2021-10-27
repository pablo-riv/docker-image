'use strict';

/**
* @name: CourierBranchOffice
* @description: Maintains CourierBranchOffice data
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
  this.app.factory('CourierBranchOffice', ['$http', '$q', function($http, $q) {
    var notWords = function(str) {
      return str.replace(/[^0-9\s]/g , '').trim().split(' ');
    };

    var notNumbers = function(str) {
      return str.replace(/[0-9\s]/g , '').trim().split(' ');
    };

    return {
      all: function() {
        var defer = $q.defer();
        $http({
          url: '/couriers_branch_offices',
          method: 'GET',
          params: {}
        }).then(function(model) {
          defer.resolve(model.data.couriers_branch_offices);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      byCouriers: function(cbos) {
        var cxp = _.filter(cbos, function(cbo){ return cbo.courier_id == 1 });
        var stk = _.filter(cbos, function(cbo){ return cbo.courier_id == 2 });
        var crr = _.filter(cbos, function(cbo){ return cbo.courier_id == 3 });
        return {cxp: cxp, stk: stk, crr: crr};
      },
      byCommune: function(cbos, commune_id) {
        return _.filter(cbos, function(cbo){ return cbo.commune_id == commune_id });
      },
      addressValues: function (cbo) {
        return {
          street: cbo.address.split(notWords(cbo.address)[0])[0],
          number: notWords(cbo.address)[0],
          commune_id: '' + cbo.commune_id,
          complement: cbo.address.split(notWords(cbo.address)[0])[1]
        };
      }
    };
  }]);
}).call(this);
