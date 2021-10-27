(function() {
  this.app.factory('Pack', ['$q', '$http', function($q, $http) {
    return {

      build: function(data, count) {
        var model = angular.extend({}, data);
        model.id = '';
        model.items_count = '';
        model.tracking_number = '';
        model.father_reference = model.reference;
        model.reference = model.reference.substring(0, 8) + '-' + (count + 1);
        model.send = false;
        return model;
      },

      findById: function(model) {
        var defer = $q.defer();
        $http({
          url: '/labels/by_reference',
          method: 'GET',
          params: {
            reference: model.reference
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      generate: function(model, packet) {
        var defer = $q.defer();
        $http({
          url: '/workspace/pack',
          method: 'POST',
          data: {
            package_id: model.id,
            packet: packet
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      dailyPrinted: function() {
        var defer = $q.defer();
        $http({
          url: '/labels/daily_printed',
          method: 'GET'
        }).then(function (model) {
          defer.resolve(model.data);
        }, function (model) {
          defer.reject(model.data);
        });
        return defer.promise;
      }

    };

  }]);
}).call(this);
