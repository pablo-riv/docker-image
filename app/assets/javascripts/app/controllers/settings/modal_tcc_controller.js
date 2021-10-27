(function() {
  this.app.controller('ModalEditTccController', ['$scope', '$uibModalInstance', 'setting', 'courier', function ($scope, $uibModalInstance, setting, courier) {
    $scope.setting = setting;
    $scope.courier = courier;

    $scope.update = function (courier) {
      $uibModalInstance.close(setting);
    };

    $scope.cancel = function () {
      $uibModalInstance.dismiss('cancel');
    };

  }]);
}).call(this);