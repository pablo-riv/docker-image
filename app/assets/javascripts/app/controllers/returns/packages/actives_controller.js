(function ()  {
  this.app.controller('PackagesReturnsActivesController', ['$scope', 'Package', '$uibModal', function ($scope, Package, $uibModal) {
    $scope.package = Package.new({ platform: 0 });
    $scope.packages = [];
    $scope.service = 'Todas';
    $scope.totalReturns;
    $scope.search = {
      per: 20,
      page: 1,
      reference: ''
    };

    $scope.addAll = function ($event) {
      if ($scope.packages.length > 0) {
        if (angular.element('#all').prop('checked')) {
          for (var index = 0; index < $scope.packages.length; index++) {
            if (index > 19) {
              alert('¡Atención! Solo puedes seleccionar hasta 20 envíos...');
              break;
            }
            $scope.packages[index]['check'] = true;
          }
        } else {
          $scope.clearAll();
        }
      }
    };

    $scope.clearAll = function ($event) {
      if ($scope.packages.length > 0) {
        for (var index = 0; index < $scope.packages.length; index++) {
          $scope.packages[index]['check'] = false;
        }
      }
    };

    $scope.countPackageChecked = function () {
      var result = _.where($scope.packages, { check: true }).length;
      if (result > 20) {
        alert('¡Atención! No puedes solicitar más de 20 envíos, se reiniciara el proceso...');
        $scope.clearAll();
      }
      return result;
    };

    $scope.countPackages = function () {
      var result = $scope.packages.length;
      return result;
    };

    $scope.loadReturns = function () {
      Package.returns(false, $scope.search).then(function (data) {
        $scope.packages = data.packages;
        $scope.totalReturns = data.total_packages;
      }, function (error) {
        console.info(error);
      });
      setTimeout(function() { angular.element('#service').val($scope.service) }, 500);
    };

    $scope.sort = function (property) {
      $scope.reverse = ($scope.property === property) ? !$scope.reverse : false;
      $scope.property = property;
    };

    $scope.getStatus = function (package) {
      var limitDate = new Date(package.automatic_retry_date)
      var currentDate = new Date();
      var difference = Math.abs(currentDate.getTime() - limitDate.getTime());
      var days = difference / (1000 * 60 * 60 * 24);
      if (currentDate > limitDate) { days *= -1; }
      if (days < 1) {
        package['statusName'] = currentDate < limitDate ? 'Menos de un día para reenviar' : 'Devolver';
      } else if (Math.round(days) == 1) {
        package['statusName'] = 'Un día para reenviar';
      } else {
        package['statusName'] = Math.round(days)  + ' días para reenviar';
      }
      package['statusKlass'] = currentDate < limitDate ? 'route' : 'fail';
    };

    $scope.openReturnConfirmation = function (package) {
      var modal = $uibModal.open({
        animation: true,
        ariaLabelledBy: 'modal-title',
        ariaDescribedBy: 'modal-body',
        templateUrl: 'returnConfirmation.html',
        controller: 'returnConfirmationModalController',
        size: 'md',
        resolve: {
          packagesCount: function () {
            return $scope.countPackageChecked();
          },
          selectedPackages: function () {
            return $scope.packages;
          }
        }
      });
      modal.result.then(function() {
      }, function(error) {
        console.log(error);
      });
    };

    $scope.pageChanged = function () {
      $scope.loadReturns();
    };
  }]).
  controller('returnConfirmationModalController' , ['$scope', '$uibModalInstance', 'packagesCount', 'selectedPackages', 'Package', function($scope, $uibModalInstance, packagesCount, selectedPackages, Package) {
    $scope.packagesCount = packagesCount; 
    $scope.packages = selectedPackages; 
    $scope.returnToClient = function () {
      $scope.loading = true;
      Package.returnToClient(_.where($scope.packages, { check: true })).then(function (data) {
        alert('Los envíos seleccionados fueron procesados.', { type: 'success' });
        window.location.href = '/returns/packages';
      }, function (error) {
        alert('Ha ocurrido un error, favor comunicarse con desarrollo.', { type: 'error' });
      });
      $scope.loading = false;
    };

    $scope.cancel = function() {
      $uibModalInstance.dismiss();
    };
  }]);
}).call(this);
