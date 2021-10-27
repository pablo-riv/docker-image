(function () {
  this.app.controller('MassiveSkusModalInstanceController', ['$scope', '$uibModalInstance', 'XlsService', 'Sku', 'skus', function ($scope, $uibModalInstance, XlsService, Sku, skus) {
    $scope.skus = skus;
    $scope.fileSkus = [];
    $scope.toReturnSkus = [];
    
    $scope.loadFile = function (event) {
      var files = event.files,
      i, f;
      for (i = 0, f = files[i]; i != files.length; ++i) {
        var reader = new FileReader();
        reader.onload = function (e) {
          var data = e.target.result;
          $scope.workbook = XLSX.read(data, { type: 'binary' });
          $scope.$apply(function functionName() {
            $scope.fileSkus = XlsService.process($scope.workbook, $scope.fileSkus, Sku.new(), { id: 0 });
          });
        };
        reader.readAsBinaryString(f);
      }
    };
    
    $scope.sumSkuList = function () {
      angular.forEach($scope.fileSkus, function (sku) {
        var selectedSku = _.find($scope.skus, function (obj) { return obj.name == sku.sku.name; });
        if (selectedSku != undefined) {
          selectedSku.qty = sku.sku.amount;
          $scope.toReturnSkus.push(angular.merge({}, selectedSku));
        }
      });
      $uibModalInstance.close($scope.toReturnSkus);
    };
    
  }]);
}).call(this);
