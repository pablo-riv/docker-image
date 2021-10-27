(function() {
  this.app.controller('HeadquarterPackageController', ['$scope', '$q', '$uibModal', 'BranchOffice', 'Package', 'Commune', 'PackageService', 'InsuranceService', 'Shipping', 'CourierService', 'CourierBranchOffice', function ($scope, $q, $uibModal, BranchOffice, Package, Commune, PackageService, InsuranceService, Shipping, CourierService, CourierBranchOffice) {
    $scope.packages = [];
    $scope.communes = [];
    $scope.model = Package.new({ platform: 0 });
    $scope.model.error = false;
    $scope.alerts = [];
    $scope.cbo = {};

    $scope.couriers = CourierService.couriers();
    $scope.old_couriers = CourierService.oldCouriers();

    $scope.destinations = ['Domicilio'];
    $scope.old_destinations = ['Domicilio'];

    $scope.error = {};
    $scope.purchaseAvailables = PackageService.purchaseAvailables();
    $scope.loadPackages = function(company) {
      Package.byBranchOfffice().then(function(data) {
        $scope.packages = data.packages;
      }, function(data) {
        console.error(data);
      });
    };

    $scope.loadCommunes = function(type) {
      $scope.model = Package.new({ platform: 0 });
      var params = type == '' || type == undefined ? 'branch_offices' : 'packages'
      Commune.all(params).then(function(data) {
        $scope.communes = data.communes;
        angular.element('select').select2({ width: '100%' });
        loadCouriersBranchOffices();
      }, function(data) {
        console.error(data);
      });
    };

    $scope.checkoutPackage = function(model) {
      var address = model.address_attributes;
      model.address_attributes.full = address.street + ' ' + address.number + ', ' + angular.element('#communes option:selected').text();
      if (model.courier_for_client === 'Chilexpress' && model.destiny === 'Starken-Turbus') {
        alert('No puedes seleccionar courier Chilexpress y enviar a Starken');
      } else if (model.courier_for_client === 'Starken' && model.destiny === 'Chilexpress') {
        alert('No puedes seleccionar courier Starken y enviar a Chilexpress');
      } else if (model.courier_for_client === 'Chilexpress' && model.destiny === 'Domicilio' && model.is_payable == true) {
        alert('No puedes realizar envíos por pagar a domicilio y con courier Chilexpress');
      } else {
        // $scope.model = $scope.transformApproxSize($scope.model);
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'checkout.html',
          controller: 'HeadquarterCheckoutController',
          size: 'lg',
          resolve: {
            model: function() {
              return $scope.model;
            },
            cost: function() {
              return {}; // $scope.getCost($scope.model);
            },
            price: function() {
              return {}; //$scope.getPrice($scope.model);
            }
          }
        });
        modal.result.then(function(model) {
        }, function(error) {
          if (error !== 'backdrop click') {
            window.location.reload(true);
          }
        });
      }
    };


    $scope.getPrice = function (model) {
      var defer = $q.defer();
      Shipping.price(model).then(function (data) {
        defer.resolve(data.shipment);
      }, function (data) {
        console.error(data);
        defer.reject(data);
      });
      return defer.promise;
    };

    $scope.getCost = function (model) {
      var defer = $q.defer();
      Shipping.cost(model).then(function (data) {
        defer.resolve(data.shipment);
      }, function (data) {
        console.error(data);
        defer.reject(data);
      });
      return defer.promise;
    };

    $scope.transformApproxSize = function(model) {
      var size = {};
      switch (model.approx_size) {
        case 'Pequeño (10x10x10cm)':
          size = { length: 10, width: 10, height: 10, weight: 1 };
          break;
        case 'Mediano(30x30x30cm)':
          size = { length: 30, width: 30, height: 30, weight: 3 }
          break;
        case 'Grande (50x50x50cm)':
          size = { length: 50, width: 50, height: 50, weight: 8 };
          break;
        case 'Muy Grande (>60x60x60cm)':
          size = { length: 60, width: 60, height: 60, weight: 20 };
        default:
          size = { length: 10, width: 10, height: 10, weight: 1 };
          break;
      }
      model.width = size.width;
      model.length = size.length;
      model.height = size.height;
      model.weight = size.weight;
      return model;
    };

    $scope.courierIcon = function(courier) {
      return Package.courierIcon(courier);
    };

    $scope.courierTrackingLink = function(model) {
      return Package.courierTrackingLink(model);
    };

    $scope.currentStatusFor = function(model) {
      return Package.currentStatusFor(model);
    };

    $scope.calculateInsurance = function (model) {
      if (model.with_purchase_insurance)  {
        $scope.model['insurance'] = InsuranceService.new(model);
      } else {
        $scope.model['insurance'] = { maxSecure: 0, amount: 0, price: 0 };
      }
    };

    $scope.validateInsurance = function () {
      if ($scope.model.with_purchase_insurance == false) {
        $scope.model.insurance_attributes.extra = false;
      }
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.validateCourier = function(data) {
      var courier = angular.element('#courier_for_client option:selected').text().toLowerCase();
      var destiny = data.destiny.toLowerCase();
      if (destiny == '') {
        return;
      }
      CourierService.rules(courier, destiny, data.is_payable).then(function(response) {
        if (!response.valid) {
          $scope.resetCourierSelectedValues();
          $scope.alerts.push({ msg: response.message, type: 'danger' });
        }
        var availablesDestinities = CourierService.availablesDestinities(courier, $scope.cbosByCouriers);
        $scope.destinations = availablesDestinities.destinations;
        $scope.old_destinations = availablesDestinities.old_destinations;
        $scope.cbo = availablesDestinities.cbos;

      }, function(error) {
        $scope.resetCourierSelectedValues();
        $scope.alerts.push({ msg: error.message, type: 'danger' });
      });
    };

    $scope.resetCourierSelectedValues = function() {
      $scope.model.destiny = 'Domicilio';
      $scope.model.is_payable = false;
    };

    $scope.changeCourierBranchOffice = function (cbo) {
      if(cbo == null || cbo == undefined){
        return false;
      }
      switch(cbo.courier_id){
        case 1:
          $scope.model.courier_for_client = 'Chilexpress';
          break;
        case 2:
          $scope.model.courier_for_client = 'Starken';
          break;
        case 3:
          $scope.model.courier_for_client = 'CorreosChile';
          break;
        default:
          break;
      }
      $scope.model.courier_branch_office_id = cbo.id
      $scope.model.address_attributes = CourierBranchOffice.addressValues(cbo);
    };

    var loadCouriersBranchOffices = function () {
      CourierBranchOffice.all().then(function(data) {
        $scope.couriersBranchOffices = data;
        $scope.cbos = $scope.couriersBranchOffices;
        $scope.cbosByCouriers = CourierBranchOffice.byCouriers($scope.couriersBranchOffices);
        angular.element('select').select2();
      }, function(error) {
        alert('No se pudo obtener la lista de sucursales de los couriers, intente denuevo mas tarde.');
      });
    };
  }]).
  controller('HeadquarterCheckoutController', ['$scope', '$uibModalInstance', 'Package', 'model', 'cost', 'price', function($scope, $uibModalInstance, Package, model, cost, price) {
    $scope.model = model;
    // $scope.cost = cost;
    // $scope.price = price;
    $scope.createPackage = function(model) {
      $scope.loading = true;
      var response = Package.valid(model);
      $scope.error = response.error;
      if (response.valid) {
        Package.create(model, 'headquarter/').then(function(data) {
          $scope.loading = false;
          alert('Solicitud recibida, pronto pasara un héroe a retirar los productos', { type: 'success' });
          window.location.href = '/headquarter/packages';
        }, function(data) {
          $scope.loading = false;
          alert('Solicitud rechazada, favor revisar los datos ingresados');
          console.error(data);
        });
      } else {
        alert('Solicitud rechazada, favor revisar los datos ingresados');
      }
    };
  }]);
}).call(this);
