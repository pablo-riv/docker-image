(function () {
  this.app.controller('EditOrderModalInstanceController', ['$scope', '$uibModalInstance', 'hasFulfillment', 'order', 'communes', 'cbos', 'Order', 'CourierService', 'OrderService', function ($scope, $uibModalInstance, hasFulfillment, order, communes, cbos, Order, CourierService, OrderService) {
    $scope.alerts = [];
    $scope.hasFulfillment = hasFulfillment;
    $scope.order = order;
    $scope.communes = communes;
    $scope.allCbos = cbos;
    // $scope.destinations = ['Domicilio', 'Chilexpress', 'Starken-Turbus', ];

    $scope.couriers = CourierService.couriers();
    $scope.destinations = ['Domicilio'];

    $scope.old_couriers = CourierService.oldCouriers();
    $scope.old_destinations = ['Domicilio'];

    $scope.availablePackings = ['Sin empaque', 'Caja de cartón', 'Film Plástico', 'Caja + Burbuja', 'Bolsa Courier + Burbuja', 'Bolsa Courier'];

    $scope.closeAlert = function (index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.updateData = function (order) {
      if (!OrderService.verifyEmailFormat(order.customer_email)) {
        return;
      }
      Order.updateOrder(order).then(function (_resolve) {
        $uibModalInstance.close(_resolve);
      }, function (_error) {

      });
    };

    $scope.loadInfo = function () {
      $scope.activeSelect2();
    };

    $scope.activeSelect2 = function () {
      angular.element('select').select2();
    };

    $scope.validateCourier = function (data) {
      var courier = angular.element('#package_courier_for_client option:selected').text().toLowerCase() == "" ? data.package_courier_for_client : angular.element('#package_courier_for_client option:selected').text().toLowerCase();
      var destiny = angular.element('#package_destiny option:selected').text().toLowerCase() == "" ? data.package_destiny : angular.element('#package_destiny option:selected').text().toLowerCase();
      if (destiny == '') {
        return;
      }
      CourierService.rules(courier, destiny, data.package_payable).then(function (response) {
        if (!response.valid) {
          $scope.resetShipment();
          $scope.alerts.push({ msg: response.message, type: 'danger' });
        }
        var availablesDestinities = CourierService.availablesDestinities(courier, $scope.allCbos);
        $scope.destinations = availablesDestinities.destinations;
        $scope.old_destinations = availablesDestinities.old_destinations;
        $scope.cbos = availablesDestinities.cbos;
      }, function (error) {
        $scope.resetShipment();
        $scope.alerts.push({ msg: error.message, type: 'danger' });
      });
    };

    $scope.addressCbo = function (cboId) {
      var abbreviatedCourier = { "starken": "stk", "chilexpress": "cxp" }
      var cbosCourier = $scope.allCbos[abbreviatedCourier[$scope.order.package_courier_for_client]]
      var cbo = _.filter(cbosCourier, function(cbo){ return cbo.id == cboId })[0]
      $scope.order.shipping_data.number = cbo.address.match(/\s\d{1,6}/)[0].trim()
      $scope.order.shipping_data.street = cbo.address.split($scope.order.shipping_data.number)[0]
      $scope.order.shipping_data_complement = cbo.address.split($scope.order.shipping_data.number)[1]
    }

    $scope.resetShipment = function () {
      $scope.order.package_payable = false;
      $scope.order_package_destiny = '';
    };

    $scope.validateCourier($scope.order);

  }]);
}).call(this);
