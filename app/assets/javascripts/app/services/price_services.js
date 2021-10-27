(function () {
  this.app.service('PriceService', ['$q', function ($q) {

    return {

      getPrice: function (data, algorithm, algorithm_days, algorithm_best_price) {
        var prices = data.prices, price = data.lower_price;

        return {
          minPrice: price,
          prices: prices,
          algorithm: algorithm,
          algorithm_days: algorithm_days,
          algorithm_best_price: algorithm_best_price
        };
      }

    };

  }]);
}).call(this);
