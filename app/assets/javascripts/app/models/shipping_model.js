(function () {
  this.app.factory('Shipping', ['$http', '$q', function ($http, $q) {
    var url = "/v/shippings";
    return {
      prices_v2: function (data) {
        var defer = $q.defer();
        var random = '';
        for (var i = 0; i < 10; i++) {
          random += Math.floor(Math.random() * 1e10);
        }
        while (random.length > 1 && random[0] == '0') random = random.substr(1);
        $http({
          url: url + '/prices_v2?random=' + random,
          method: 'POST',
          data: { package: data }
        }).then(function (model) {
          defer.resolve(model.data);
        }, function (model) {
          defer.reject(model.data);
        });

        return defer.promise;
      },

      prices_v3: function (data) {
        var defer = $q.defer();
        $http({
          url: '/v/prices',
          method: 'POST',
          headers: {
            'Accept': 'application/vnd.shipit.v3'
          },
          data: { package: data }
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
