(function () {
  this.app.controller('PackController', ['$scope', '$timeout', 'Pack', 'PackService', 'CourierService', function ($scope, $timeout, Pack, PackService, CourierService) {
    $scope.packageLoaded = false;
    $scope.model = { reference: '' };
    $scope.alerts = [];
    $scope.packages = [];

    $scope.init = function () {
      $scope.alerts.push({ message: 'Ingresar o Pistolear envío', type: 'info' });
      doFocus();
      Pack.dailyPrinted().then(function(data) {
        $scope.packages = data.packages;
      }, function(error) {
        $scope.alerts.push({ message: 'No se encontraron pedidos impresos', type: 'danger' });
      });
    };

    $scope.findPackage = function (model, $event) {
      $scope.packageLoaded = true;
      PackService.findPackage(model, $event).then(function (data) {
        checkProcess(data.alert, data.package);
      }, function (error) {
        checkErrorType(error);
      });
    };

    $scope.validateCount = function (pack) {
      pack.items_count = ((isNaN(pack.items_count) || pack.items_count == null || pack.items_count == "" || pack.items_count >= $scope.current.current_items_count == pack.items_count) ? 0 : pack.items_count);
    };

    $scope.exit = function () {
      var confirm = window.confirm('¿Estas seguro de reiniciar el proceso?');
      if (confirm) {
        restartProcess();
      }
    };

    var checkErrorType = function (error) {
      if (error.state == 'error') {
        $scope.alerts.push({ message: error.message, type: 'danger' });
        restartProcess();
      } else {
        $scope.packageLoaded = false;
        doFocus();
      }
    };

    var checkProcess = function (alert, model) {
      $scope.packages.unshift(model)
      $timeout(function () { restartProcess(); }, 0);
      if (alert !== '') {
        $scope.alerts.push({ message: alert, type: 'danger' });
      }
    };

    var restartProcess = function () {
      $scope.model = { id: '' };
      $scope.packageLoaded = false;
      $timeout(function () { doFocus(); }, 0);
    };

    var doFocus = function () {
      angular.element('#automatic-package-id').focus();
    };

    $scope.closeAlert = function (index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.getIcon = function (courier) {
      return ['', undefined, null].includes(courier) ? '' : CourierService.getIcon(courier.toLowerCase());
    };

    $scope.statusColor = function (averyPrinted) {
      return averyPrinted ? 'delivery' : 'not-printed';
    };

  }]);
}).call(this);
