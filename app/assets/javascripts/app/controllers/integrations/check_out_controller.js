(function() {
  this.app.controller('IntegrationCheckoutModalInstanceController', ['$scope', '$uibModalInstance', 'hasFulfillment', 'rows', 'Order', function($scope, $uibModalInstance, hasFulfillment, rows, Order) {
    $scope.alerts = [];
    $scope.hasFulfillment = hasFulfillment;
    $scope.rows = rows;
    $scope.loading = false;

    $scope.createPackages = function($event) {
      $event.currentTarget.disabled = true;
      $scope.loading = true;
      Order.createOrders($scope.rows).then(function(data) {
        $scope.alerts.push({ msg: data.response, type: 'success' });
        if (data.errors != '') {
          $scope.alerts.push({ msg: data.errors, type: 'warning' });
        }
      }, function(error) {
        $scope.alerts.push({ msg: error, type: 'danger' });
      });
    };

    $scope.closeAlert = function(index) {
      window.location.reload();
    };
  }]);
}).call(this);
