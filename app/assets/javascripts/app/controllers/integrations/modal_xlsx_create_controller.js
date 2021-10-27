(function () {
  this.app.controller('OrderXlsxCreateModalController', ['$scope', '$uibModalInstance', 'XlsService', function ($scope, $uibModalInstance, XlsService) {
    $scope.alerts = [];
    $scope.workbook = [];
    $scope.orders = [];
    $scope.ready = false;
    $scope.errors = false;
    $scope.loadFile = function (event) {
      var files = event.files, i, f;
      for (i = 0, f = files[i]; i != files.length; ++i) {
        var reader = new FileReader();
        reader.onload = function (e) {
          $scope.workbook = XLSX.read(e.target.result, { type: 'binary' });
          $scope.$apply(function () {
            XlsService.processMassiveOrderToCreate($scope.workbook).then(function (orders) {
              $scope.orders = orders;
              $scope.ready = true;
            }, function (error) {
              $scope.alerts.push({ type: 'danger', message: 'No se han encontrado ordenes...' });
              $scope.ready = true;
            })
          });
        };
        reader.readAsBinaryString(f);
      }
    };

    $scope.createPackages = function (orders) {
      $scope.orders = _.reject(orders, function (o) {
        if (o.customer_name_error == true ||
            o.shipping_data_street_error == true ||
            o.shipping_data_number_error == true ||
            o.commune_name_error == true ||
            o.undetected_error == true) {
          return true;
        } else {
          return false;
        }
      });

      var references = _.difference(orders, $scope.orders).map(function(difference) {
        return difference.seller_reference;
      });
      
      alert("Las siguientes ordenes seran omitidas, debido a que estan incompletas: " + references.join(', '))

      $uibModalInstance.close($scope.orders);
    };

    $scope.cancel = function () {
      $uibModalInstance.dismiss();
    };

    $scope.remove = function(order) {
      $scope.orders = _.reject($scope.orders, function (o) {
        return o.seller_reference == order.seller_reference && o.seller == order.seller
      });
    };

    $scope.orderError = function(order, attr) { return eval("order." + attr); };

  }]);
}).call(this);