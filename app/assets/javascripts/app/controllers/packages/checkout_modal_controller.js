(function () {
  this.app.controller('PackageCheckoutModalInstanceController', ['$scope', '$uibModalInstance', 'Package', 'Shipping', 'PriceService', 'checkoutPackage', 'hasFulfillment', 'skus', 'Negotiation', function ($scope, $uibModalInstance, Package, Shipping, PriceService, checkoutPackage, hasFulfillment, skus, Negotiation) {
    $scope.package = checkoutPackage;
    $scope.hasFulfillment = hasFulfillment;
    $scope.skus = skus;
    $scope.prices = [];
    
    $scope.getPrices = function() {
      if (['retiro cliente', 'despacho retail'].includes($scope.package.destiny.toLowerCase()) || $scope.package.without_courier) {
        return;
      } else if (![null, '', void (0)].includes($scope.package.courier_for_client) || $scope.package.algorithm == 2) {
        $scope.loading = true;
        var objectPrice = {
          to_commune_id: parseInt($scope.package.address_attributes.commune_id),
          height: $scope.package.height,
          width: $scope.package.width,
          length: $scope.package.length,
          weight: $scope.package.weight,
          algorithm: '',
          algorithm_days: '',
          destinity: $scope.package.destiny,
          is_payable: $scope.package.is_payable,
          courier_selected: $scope.package.courier_selected || false,
          courier_for_client: $scope.package.courier_selected || false ? $scope.package.courier_for_client : ''
        };
        Shipping.prices_v3(objectPrice).then(function (_data) {
          $scope.objectPrices = PriceService.getPrice(_data);
          $scope.pricingAvailable = true;
          $scope.loading = false;
        }, function (_error) {
          $scope.pricingAvailable = false;
          $scope.loading = false;
          console.table(_error);
        });
      }
    };

    var validatePackage = function () {
      var valid = Package.valid($scope.package);
      var fields = fieldsToCheck(valid.error);
      if (valid.valid == false && fields.length > 0) {
        var toCheck = '';
        angular.forEach(fields, function (f) { toCheck += (f + ', '); });
        var errorMessage = 'Revisa los campos ' + toCheck;
        alert(errorMessage);
      }
      return valid.valid;
    };
    
    var fieldsToCheck = function (object) {
      var listOfFields = [];
      var packageFieldsTranslate = Package.fieldsTranslate();
      angular.forEach(Object.keys(object), function (key) {
        if (key == 'address_attributes') {
          _.union(listOfFields, fieldsToCheck(object[key]));
        } else {
          if (object[key] == true) {
            listOfFields.push(packageFieldsTranslate[key]);
          }
        }
      });
      return listOfFields;
    };
    
    $scope.generatePackage = function () {
      $scope.loading = true;
      if (validatePackage()) {
        var packageToCreate = $scope.package;
        if ($scope.hasFulfillment) {
          packageToCreate.inventory_activity = { 'inventory_activity_orders_attributes': [] };
          packageToCreate.items_count = 0;
          angular.forEach($scope.skus, function (sku) {
            var inventoryOrder = { sku_id: sku.id, amount: sku.qty, warehouse_id: sku.warehouse_id };
            packageToCreate.items_count += sku.qty;
            packageToCreate.inventory_activity.inventory_activity_orders_attributes.push(inventoryOrder);
          });
        }
        Package.create(packageToCreate, '').then(function (data) {
          alert('Envío creado exitosamente!', { type: 'success' });
          window.location.href = '/packages/' + data.package[0].id;
        }, function (error) {
          window.location.href = '/packages/new';
          alert('Hubo un problema intentando procesar su solicitud, intente denuevo mas tarde.');
        });
      } else {
        $scope.loading = false;
      }
    };

    $scope.generateReturnPackage = function () {
      $scope.loading = true;
      if (validatePackage()) {
        var packageToCreate = $scope.package;
        if ($scope.hasFulfillment) {
          packageToCreate.inventory_activity = { 'inventory_activity_orders_attributes': [] };
          packageToCreate.items_count = 0;
          angular.forEach($scope.skus, function (sku) {
            var inventoryOrder = { sku_id: sku.id, amount: sku.qty, warehouse_id: sku.warehouse_id };
            packageToCreate.items_count += sku.qty;
            packageToCreate.inventory_activity.inventory_activity_orders_attributes.push(inventoryOrder);
          });
        }
        Package.createReturn(packageToCreate).then(function (data) {
          window.location.href = '/packages/' + $scope.package.id;
        }, function (error) {
          alert('Hubo un problema intentando procesar su solicitud, intente denuevo mas tarde.');
          window.location.href = '/packages/return/new/'+$scope.package.id;
        });
      } else {
        $scope.loading = false;
      }
    };

    $scope.editPackage = function() {
      edited = $scope.package;
      $scope.loading = true;
      if (validatePackage()){
        Package.update(edited).then(function (data){
          alert('Envío editado exitosamente!', { type: 'success' });
          window.location.href = '/packages/' + $scope.package.id;
        }, function (error) {
          alert('Hubo un problema intentando procesar su solicitud, intente denuevo mas tarde.');
          window.location.href = '/packages/' + $scope.package.id + '/edit';
        });
      } else {
        $scope.loading = false;
      }
    }

    $scope.closeAlert = function (index) {
      window.location.reload();
    };

    $scope.selectedPrice = function(courierIterator, courierSelected, courier_for_client) {
      if (courier_for_client == courierIterator.courier.name || courierIterator.courier.name == courierSelected.courier.name) {
        $scope.updateCourierForClient(courierIterator, $scope.objectPrices.prices);
      } else {
        courierIterator.selected = false;
        $scope.package.courier_for_client = null;
        $scope.package.shipping_price = null;
        $scope.package.shipping_cost = null;
        $scope.package.volume_price = null
        $scope.package.courier_selected = false;
      }
    };

    $scope.updateCourierForClient = function(price, prices) {
      if (prices.length > 0) {
        _.map(prices, function (value, index) { value.selected = false; });
        $scope.package.courier_for_client = price.courier.name;
        $scope.package.courier_selected = true;
        $scope.package.volume_price = price.volumetric_weight;
        $scope.package.shipping_price = price.price;
        $scope.package.shipping_cost = price.cost;
        price.selected = true;
      }
    };

  }]);
}).call(this);
