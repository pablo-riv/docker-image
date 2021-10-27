'use strict';
(function() {
  this.app.factory('Label', ['$q', '$http', function($q, $http) {
    return {
      todayWithoutChecks: function(search) {
        console.log(search)
        var defer = $q.defer();
        $http({
          url: '/labels/today',
          method: 'GET',
          params: {
            page: search.page,
            from: search.from,
            to: search.to,
            per: search.per,
            courier: search.courier,
            commune: search.commune,
            reference: search.reference,
            seller: search.seller,
            payable: search.payable,
            destiny: search.destiny
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      search: function(search) {
        var defer = $q.defer();
        $http({
          url: '/labels/search',
          method: 'GET',
          params: {
            from: search.from,
            to: search.to
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      create: function(packages) {
        var defer = $q.defer();
        $http({
          url: '/v/printers',
          method: 'POST',
          headers: {
            'Accept': 'application/vnd.shipit.v3'
          },
          data: {
            packages: _.pluck(packages, 'id')
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      printerJob: function() {
        var defer = $q.defer();
        $http({
          url: '/v/printers/massive',
          method: 'POST',
          headers: {
            'Accept': 'application/vnd.shipit.v3'
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
