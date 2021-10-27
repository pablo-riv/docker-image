(function () {
  this.app.controller('PackageReturnsDeliverController', ['$scope', '$q', 'Package', 'InsuranceService', 'PackageService', 'CourierBranchOffice', 'Commune', 'CourierService', function ($scope, $q, Package, InsuranceService, PackageService, CourierBranchOffice, Commune, CourierService) {
    $scope.alerts = []
    $scope.package = {};
    $scope.couriers = CourierService.couriers();
    $scope.destinations = ['Domicilio', 'Chilexpress', 'Starken-Turbus', 'CorreosChile', 'DHL', 'MuvSmart', 'Glovo', 'Moto Partner', 'Chile Parcels', 'Bluexpress', 'Shippify'];
    $scope.sizes = ['Pequeño (10x10x10cm)', 'Mediano (30x30x30cm)', 'Grande (50x50x50cm)', 'Muy Grande (>60x60x60cm)'];
    $scope.packings = ['Sin empaque', 'Caja de Cartón', 'Film Plástico', 'Caja + Burbuja', 'Papel Kraft', 'Bolsa Courier + Burbuja', 'Bolsa Courier'];
    $scope.package.error = false;
    $scope.purchaseAvailables = PackageService.purchaseAvailables();
    $scope.findPackage = function (id) {
      Package.find(id).then(function(_resolve) {
        $scope.alerts.push({ message: 'Envío cargado correctamente, ingresa los datos para generar la devolución.', type: 'success' });
        loadCommunes();
        loadCouriersBranchOffices();
        $scope.package = Package.newReturn(_resolve.package);
      }, function(_error) {
        $scope.alerts.push({ message: 'Envío no encontrado', type: 'danger' });
      });
    };

    $scope.checkoutPackage = function () {
      try {
        if ($scope.validAddress($scope.package.address_attributes)) {
          var address = $scope.package.address_attributes;
          $scope.package.address_attributes.full = address.street + ' ' + address.number + ', ' + angular.element('#communes option:selected').text().toLowerCase();
          $scope.courierForClient($scope.package).then(function () {
            PackageService.validate($scope.package).then(function () {
              PackageService.lauchModal($scope.package, false, [], 'ReturnPackageCheckoutModalInstanceController');
            }, function (data) {
              $scope.alerts.push({ message: data.message, type: 'danger' });
              $scope.package.error = true;
            });
          }, function (error) {
            $scope.alerts.push({ message: error, type: 'danger' });
          }); 
        } else {
          $scope.alerts.push({ message: '¡Debes ingresar una direccion valida!', type: 'danger' });
        }
      } catch (error) {
        $scope.alerts.push({ message: error, type: 'danger' });
      }
    };

    $scope.validAddress = function(address) {
      var valid = true;
      if (address == undefined) {
        valid = false;
      } else if (address.street == '') {
        valid = false;
      } else if (address.number == '') {
        valid = false;
      } else if (address.commune_id == '') {
        valid =  false;
      }
      return valid;
    };

    $scope.courierForClient = function (package) {
      var defer = $q.defer();
      if (package.without_courier) {
        package.destiny = 'Retiro Cliente'
        package.courier_for_client = 'Shipit'
        package.courier_selected = true;
        defer.resolve();
      } else if (!package.without_courier) {
        defer.resolve();
      }
      return defer.promise;
    };

    $scope.checkPayable = function () {
      if ($scope.package.is_payable && $scope.package.destiny == 'Domicilio' && $scope.package.courier_for_client == 'Chilexpress') {
        $scope.package.is_payable = false;
        $scope.changeCourier();
        $scope.alerts.push({ message: 'No puedes realizar envíos por pagar a domicilio y con courier Chilexpress', type: 'danger' });
      }
    };

    $scope.defaulAddress = function (package) {
      if (package.without_courier) {
        package['address_attributes'] = { street: 'El Roble', number: '970', complement: 'Oficina / Bodega 21', commune_id: 331 };
        package.destiny = 'Retiro Cliente';
      } else {
        package.address_attributes.street = '';
        package.address_attributes.number = '';
        package.address_attributes.complement = '';
        package.address_attributes.commune_id = 0;
      }
      setTimeout(function () { $scope.activeSelect2() }, 500);
    };

    $scope.calculateInsurance = function (package) {
      if (package.with_purchase_insurance) {
        $scope.package['insurance'] = InsuranceService.new(package);
      } else {
        $scope.package['insurance'] = { maxSecure: 0, amount: 0, price: 0 };
      }
    };

    $scope.validateInsurance = function () {
      if ($scope.package.with_purchase_insurance == false) {
        $scope.package.insurance_attributes.extra = false;
      }
    };

    var loadCouriersBranchOffices = function () {
      CourierBranchOffice.all().then(function (data) {
        $scope.couriersBranchOffices = data;
        $scope.cbos = $scope.couriersBranchOffices;
        $scope.cbosByCouriers = CourierBranchOffice.byCouriers($scope.couriersBranchOffices);
        setTimeout(function () { $scope.activeSelect2() }, 500);
      }, function (error) {
        $scope.alerts.push({ message: 'No se pudo obtener la lista de sucursales de los couriers, intente denuevo mas tarde.', type: 'danger' });
      });
    };

    $scope.changeCourierBranchOffice = function (cbo) {
      if (cbo == null || cbo == undefined) {
        return false;
      }
      switch (cbo.courier_id) {
        case 1:
          $scope.package.courier_for_client = 'Chilexpress';
          break;
        case 2:
          $scope.package.courier_for_client = 'Starken';
          break;
        case 3:
          $scope.package.courier_for_client = 'CorreosChile';
          break;
        default:
          break;
      }
      $scope.package.courier_branch_office_id = cbo.id
      $scope.package.address_attributes = CourierBranchOffice.addressValues(cbo);
    };

    var loadCommunes = function () {
      Commune.all('all').then(function (data) {
        $scope.communes = data.communes;
        setTimeout(function () { $scope.activeSelect2() }, 500);
      }, function (error) {
        $scope.alerts.push({ message: 'No se pudo obtener la lista de comunas, intente denuevo mas tarde.', type: 'danger' });
      });
    };

    $scope.changeCourier = function () {
      if ($scope.package.courier_for_client == undefined) {
        return;
      } else if ($scope.package.courier_for_client.toLowerCase() == 'chilexpress' && $scope.package.is_payable == true) {
        $scope.destinations = ['Chilexpress'];
        $scope.destiny = 'Chilexpress';
        $scope.cbos = $scope.cbosByCouriers.cxp;
      } else {
        switch ($scope.package.courier_for_client.toLowerCase()) {
          case 'chilexpress':
            $scope.destinations = ['Domicilio', 'Chilexpress'];
            $scope.cbos = $scope.cbosByCouriers.cxp;
            break;
          case 'starken':
            $scope.destinations = ['Domicilio', 'Starken-Turbus'];
            $scope.cbos = $scope.cbosByCouriers.stk;
            break;
          case 'correoschile':
            $scope.destinations = ['Domicilio', 'CorreosChile'];
            $scope.cbos = $scope.cbosByCouriers.cc;
            break;
          case 'glovo':
          case 'chileparcels':
          case 'motopartner':
          case 'bluexpress':
            $scope.destinations = ['Domicilio'];
            break;
          default:
            $scope.destinations = ['Domicilio', 'Chilexpress', 'Starken-Turbus', 'CorreosChile'];
            $scope.cbos = $scope.couriersBranchOffices;
            break;
        }
      }
      setTimeout(function () { $scope.activeSelect2() }, 500);
    };

    $scope.changeDestiny = function () {
      setTimeout(function () { $scope.activeSelect2() }, 500);
      if ($scope.package.destiny == 'Domicilio' && $scope.package.courier_for_client == 'Chilexpress' && $scope.package.is_payable == true) {
        $scope.alerts.push({ message: 'No puedes realizar envíos por pagar a domicilio y con courier Chilexpress', type: 'danger' });
        resetCourierSelectedValues();
      } else if ($scope.package.destiny == 'Chilexpress' && $scope.package.courier_for_client == 'Starken') {
        $scope.alerts.push({ message: 'No puedes realizar envíos por Starken y enviar a Sucursal Chilexpress', type: 'danger' });
        resetCourierSelectedValues();
      } else if ($scope.package.destiny == 'Starken-Turbus' && $scope.package.courier_for_client == 'Chilexpress') {
        $scope.alerts.push({ message: 'No puedes realizar envíos por Chilexpress y enviar a Sucursal Starken', type: 'danger' });
        resetCourierSelectedValues();
      }
    };

    var resetCourierSelectedValues = function () {
      $scope.package.courier_for_client = '';
      $scope.package.destiny = '';
      $scope.package.is_payable = false;
    };

    $scope.changeCommuneSelected = function () {
      $scope.cbos = CourierBranchOffice.byCommune(selectedDestinyCourierBO(), $scope.package.address_attributes.commune_id);
    };

    var selectedDestinyCourierBO = function () {
      var filtered = [];
      switch ($scope.package.destiny) {
        case 'Chilexpress':
          filtered = $scope.cbosByCouriers.cxp;
          break;
        case 'Starken-Turbus':
          filtered = $scope.cbosByCouriers.stk;
          break;
        default:
          filtered = $scope.couriersBranchOffices;
          $scope.package.courier_branch_office_id = 0;
          break;
      };
      $scope.cbos = filtered;
      return filtered;
    };

    $scope.activeSelect2 = function () {
      angular.element('select').select2();
    };
  }]).
  controller('ReturnPackageCheckoutModalInstanceController', ['$scope', '$uibModalInstance', 'Package', 'checkoutPackage', function ($scope, $uibModalInstance, Package, checkoutPackage) {
    $scope.alerts = [];
    $scope.package = checkoutPackage;
    var validatePackage = function () {
      var valid = Package.valid($scope.package);
      var fields = fieldsToCheck(valid.error);
      if (valid.valid == false && fields.length > 0) {
        var toCheck = '';
        angular.forEach(fields, function (f) { toCheck += (f + ', '); });
        var errorMessage = 'Revisa los campos ' + toCheck;
        $scope.alerts.push({ message: errorMessage, type: 'danger' });
      }
      return valid.valid;
    };

    var fieldsToCheck = function (object) {
      var listOfFields = [];
      var packageFieldsTranslate = Package.fieldsTranslate();
      angular.forEach(Object.keys(object), function (key) {
        if (key == 'address_attributes') {
          _.union(listOfFields, fieldsToCheck(object[key]));
        }
        else {
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
        Package.createReturn(packageToCreate).then(function (data) {
          $scope.alerts.push({ message: '¡Envío creado exitosamente!', type: 'success' });
          window.location.href = '/returns/packages';
        }, function (error) {
          $scope.alerts.push({ message: 'Hubo un problema intentando procesar su solicitud, intente denuevo mas tarde.', type: 'danger' });
          window.location.href = '/returns/packages';
        });
      } else {
        $scope.loading = false;
      }
    };

    $scope.closeAlert = function (index) {
      window.location.reload();
    };
  }]);
}).call(this);