(function () {
  this.app.controller('OrderXlsxModalController', ['$scope', '$uibModalInstance', 'XlsService', function ($scope, $uibModalInstance, XlsService) {
    $scope.alerts = [];
    $scope.workbook = [];
    $scope.packages = [];
    $scope.ready = false;
    $scope.loadFile = function (event) {
      var files = event.files, i, f;
      for (i = 0, f = files[i]; i != files.length; ++i) {
        var reader = new FileReader();
        reader.onload = function (e) {
          $scope.workbook = XLSX.read(e.target.result, { type: 'binary' });
          $scope.$apply(function() {
            XlsService.processMassiveOrderPrint($scope.workbook).then(function(packages) {
              $scope.packages = packages;
              $scope.ready = true;
            }, function(error) {
              $scope.alerts.push({ type: 'danger', message: 'No se han encontrado envíos...' });
              $scope.ready = true;
            })
          });
        };
        reader.readAsBinaryString(f);
      }
    };

    $scope.print = function(packages) {
      $uibModalInstance.close(packages);
    };

    $scope.cancel = function () {
      $uibModalInstance.dismiss();
    };

  }]);
}).call(this);