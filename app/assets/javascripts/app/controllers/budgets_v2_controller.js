(function () {
  this.app.controller('BudgetsV2Controller', ['$scope', 'Shipping', 'Commune', 'Setting', 'CourierService', 'Negotiation', function ($scope, Shipping, Commune, Setting, CourierService, Negotiation) {
    $scope.hide = true;
    $scope.package = {
      commune_from_id: 308,
      commune_to_id: '',
      height: 10,
      width: 10,
      length: 10,
      weight: 1,
      algorithm: 1,
      algorithm_days: ''
    };
    $scope.communes = [];
    $scope.prices = [];
    $scope.algorithm = 1;
    $scope.algorithm_days = '';
    $scope.min_price = 0;
    $scope.settings = [];
    $scope.select_communes = undefined;
    $scope.commune_name = 'Sin definir';

    $scope.loadCommunes = function (type) {
      $scope.isReady = false;
      var params = type == '' || type == undefined ? 'branch_offices' : 'packages';
      Commune.all(params).then(function (data) {
        $scope.isReady = true;
        $scope.communes = data.communes;
        $scope.package.commune_from_id = _.find($scope.communes, function (commune) { return commune.name == 'LAS CONDES' })
        $scope.package.commune_from_id = $scope.package.commune_from_id ? $scope.package.commune_from_id.id : 308
        $scope.select_communes = angular.element('select').select2({ width: '100%' });
        Setting.current(1).then(function (settings) {
          if (settings.configuration.opit.algorithm) {
            $scope.algorithm = parseInt(settings.configuration.opit.algorithm);
            if (settings.configuration.opit.algorithm_days) {
              $scope.algorithm_days = parseInt(settings.configuration.opit.algorithm_days);
            }
          }
        }, function (data) {
          console.error(data);
        });
      }, function (data) {
        console.error(data);
      });
    };

    $scope.submitForm = function (package) {
      $scope.hide = true;
      $scope.loading = true;
      Shipping.prices_v2(package).then(function (data) {

        var range_prices = [];
        $scope.commune_name = $("#communes option[value='number:" + package.commune_to_id + "']").html();
        $scope.loading = false;
        $scope.hide = false;
        $scope.prices = data.prices;
        $scope.min_price = data.lower_price;
      }, function (data) {
        $scope.hide = false;
        $scope.loading = false;
        console.error(data);
      });
    };

    $scope.validateNumber = function (value, name) {
      if (value !== undefined) {
        typeof value === 'number' ? value = value.toString() : null;
        $scope.package[name] = value = value.replace(/[^0-9\.]+/g, '').replace(/,/g, '');
        if (value.split('.').length > 2) {
          $scope.package[name] = value.substring(0, (value.length - 1));
        }
      }
    };

    $scope.validShip = function (package) {
      if (package.width === '' || package.height === '' || package.length === '' || package.weight === '' || package.commune_from_id === '' || package.commune_to_id === '') {
        return true;
      } else {
        return false;
      }
    };

    $scope.getIcon = function (courier) {
      return CourierService.getIcon(courier);
    };


  }]);
}).call(this);
