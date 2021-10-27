(function() {
  this.app.controller('BudgetsController', ['$scope', 'Shipping', 'Commune', function($scope, Shipping, Commune) {
    $scope.hide = true;
    $scope.package = {
      height: 10,
      width: 10,
      length: 10,
      weight: 1,
      is_payable: false,
      destiny: 'Domicilio',
      courier_for_client: '',
      address_attributes: {
        commune_id: null
      }
    };
    $scope.communes = [];
    $scope.prices = [];
    $scope.min_price = 0;
    $scope.loadCommunes = function(type) {
      $scope.isReady = false;
      var params = type == '' || type == undefined ? 'branch_offices' : 'packages'
      Commune.all(params).then(function(data) {
        $scope.isReady = true;
        $scope.communes = data.communes;
        angular.element('select').select2({ width: '100%' });
      }, function(data) {
        console.error(data);
      });
    };

    $scope.submitForm = function(package) {
      $scope.hide = true;
      $scope.loading = true;
      Shipping.prices(package).then(function(data) {
        var range_prices = [];
        $scope.loading = false;
        $scope.hide = false;
        $scope.prices = data.shipments;
        range_prices = _.pluck(data.shipments, 'total');
        $scope.min_price = _.min(range_prices);
      }, function(data) {
        $scope.hide = false;
        $scope.loading = false;
        console.error(data);
      });
      Shipping.price(package).then(function (data) {
        $scope.price = data.shipment;
      }, function(data) {
        console.error(data);
      });
      Shipping.cost(package).then(function (data) {
        $scope.cost = data.shipment;
      }, function(data) {
        console.error(data);
      });
    };

    $scope.validateNumber = function(value, name) {
      if (value !== undefined) {
        typeof value === 'number' ? value = value.toString() : null;
        $scope.package[name] = value = value.replace(/[^0-9\.]+/g, '').replace(/,/g, '');
        if (value.split('.').length > 2) {
          $scope.package[name] = value.substring(0, (value.length - 1));
        }
      }
    };

    $scope.validShip = function(package) {
      if (package.width === '' || package.height === '' || package.length === '' || package.weight === '' || package.address_attributes.commune_id === null) {
        return true;
      } else {
        return false;
      }
    };

  }]);
}).call(this);
