(function () {
  this.app.controller('PackagesReturnsProcessedController', ['$scope', 'Package', 'CourierService', 'StatusService', function ($scope, Package, CourierService, StatusService) {
    $scope.package = Package.new({ platform: 0 });
    $scope.packages = [];
    $scope.service = 'Todas';
    $scope.totalReturns;
    $scope.search = {
      per: 20,
      page: 1,
      reference: ''
    };
    $scope.loadReturns = function () {
      Package.returns(true, $scope.search).then(function (data) {
        $scope.packages = data.packages;
        $scope.totalReturns = data.total_packages;
      }, function (error) {
        console.info(error);
      });
      setTimeout(function () { angular.element('#service').val($scope.service) }, 500);
    };

    $scope.sort = function (property) {
      $scope.reverse = ($scope.property === property) ? !$scope.reverse : false;
      $scope.property = property;
    };

    $scope.getStatus = function (package) {
      var limitDate = new Date(package.automatic_retry_date)
      var currentDate = new Date();
      package['statusName'] = currentDate < limitDate ? 'En Espera' : 'Devolver';
      package['statusKlass'] = currentDate < limitDate ? 'route' : 'fail';
    };

    $scope.getIcon = function (courier) {
      return CourierService.icon(courier);
    };

    $scope.getColor = function (courier) {
      return CourierService.color(courier);
    };

    $scope.statusColor = function (status) {
      return StatusService.color(status);
    };

    $scope.statusText = function (status) {
      return StatusService.text(status);
    };

    $scope.filterTable = function (service) {
      Package.returns(true).then(function (data) {
        fillPackages(data.packages);
      }, function (error) {
        console.info(error);
      });
    };

    var fillPackages = function (packages) {
      if ($scope.service == 'Fulfillment') {
        $scope.packages = _.filter(packages, function (package) { if (package.inventory_activity != null && package.inventory_activity != undefined) return package; });
      } else if ($scope.service == 'Pick and Pack') {
        $scope.packages = _.filter(packages, function (package) { if (package.inventory_activity == null || package.inventory_activity == undefined) return package });
      } else {
        $scope.packages = packages;
      };
    };

  }]);
}).call(this);