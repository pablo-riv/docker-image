(function () {
  this.app.controller('PackagesController', ['$scope', '$q', '$uibModal', 'Package', 'Commune', 'Sku', 'CourierBranchOffice', 'PackageService', 'InsuranceService', 'CourierService', 'Setting', function ($scope, $q, $uibModal, Package, Commune, Sku, CourierBranchOffice, PackageService, InsuranceService, CourierService, Setting) {
    $scope.package = Package.new({ platform: 0 });
    $scope.hasFulfillment = false;
    $scope.selectedSku = {};
    $scope.alerts = [];
    $scope.settings = [];
    $scope.availableDestiniesStarken = [];
    $scope.shippest_in_x_days = "Envío más barato a X días";
    $scope.algorithm_days = "";
    $scope.couriers = CourierService.couriers();
    $scope.old_couriers = CourierService.oldCouriers();

    $scope.findPackage = function (package) {
      $scope.package = Package.newReturn(package);
      $scope.package.cellphone = parseInt(package.cellphone);
      loadCommunes();
      loadCouriersBranchOffices();
    };

    Setting.current(1).then(function (settings) {
      if (settings.configuration.opit.algorithm) {
        $scope.package.algorithm = parseInt(settings.configuration.opit.algorithm);
        if (settings.configuration.opit.algorithm_days) {
          $scope.package.algorithm_days = parseInt(settings.configuration.opit.algorithm_days);
          $scope.algorithm_days = parseInt(settings.configuration.opit.algorithm_days);
        }

        if (parseInt($scope.package.algorithm) == 2) {
          $scope.shippest_in_x_days = $scope.shippest_in_x_days.replace("X", $scope.algorithm_days);
          $scope.couriers.unshift({ name: $scope.shippest_in_x_days, value: '' });
          $scope.old_couriers.unshift({ name: $scope.shippest_in_x_days, value: '' });

          setTimeout(function () {
            $("#courier_for_client option:eq(0)").prop('selected', true).change();
          }, 1000);

        }
      }
    });

    $scope.destinations = ['Domicilio'];

    $scope.old_destinations = ['Domicilio'];
    $scope.sizes = ['Pequeño (10x10x10cm)', 'Mediano (30x30x30cm)', 'Grande (50x50x50cm)', 'Muy Grande (>60x60x60cm)'];
    $scope.packings = ['Sin empaque', 'Caja de Cartón', 'Film Plástico', 'Caja + Burbuja', 'Bolsa Courier + Burbuja', 'Bolsa Courier'];
    $scope.package.error = false;
    $scope.cbo = {};
    $scope.notification = {};
    $scope.purchaseAvailables = PackageService.purchaseAvailables();
    var resetSkuValues = function () {
      $scope.selectedSku = {};
      //$scope.fileSkus = [];
      //angular.element('#uploadXls').val('');
    };

    $scope.closeAlert = function (index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.validateCourier = function (data) {
      var courier = angular.element('#courier_for_client option:selected').text().toLowerCase();
      var communeName = angular.element('#communes option:selected').text().toUpperCase();
      var destiny = data.destiny.toLowerCase();
      if (destiny == '') {
        return;
      }

      switch (courier.replace(/ +/g, "").toLowerCase()) {
        case 'chilexpress':
        case 'starken':
        case 'correoschile':
        case 'dhl':
        case 'shippify':
        case 'chileparcels':
        case 'motopartner':
        case 'bluexpress':
          data.courier_selected = true;
          break;
        default:
          data.courier_selected = false;
          break;
      }

      var hasAlgorithmDays = (angular.element('#courier_for_client option:selected').text() == $scope.shippest_in_x_days);
      if (!hasAlgorithmDays) {
        $scope.package.algorithm = 1;
        $scope.package.algorithm_days = "";
      } else {
        $scope.package.algorithm = 2;
        $scope.package.algorithm_days = $scope.algorithm_days;
        $scope.package.is_payable = false;
      }

      CourierService.rules(courier, destiny, data.is_payable, $scope.availableDestiniesStarken, communeName).then(function (response) {
        if (!response.valid) {
          $scope.resetCourierSelectedValues();
          $scope.alerts.push({ msg: response.message, type: 'danger' });
        }
        var availablesDestinities = CourierService.availablesDestinities(courier, $scope.cbosByCouriers);
        $scope.destinations = availablesDestinities.destinations;
        $scope.old_destinations = availablesDestinities.old_destinations;
        $scope.cbos = availablesDestinities.cbos;

      }, function (error) {
        $scope.resetCourierSelectedValues();
        $scope.alerts.push({ msg: error.message, type: 'danger' });
      });
    };

    $scope.resetCourierSelectedValues = function () {
      $scope.package.destiny = 'Domicilio';
      $scope.package.is_payable = false;
    };

    var loadCommunes = function () {
      Commune.all('').then(function (data) {
        $scope.communes = data.communes;
        angular.element('select').select2();
        loadAvailablesStarkenDestinies();
        $scope.package.address_attributes = $scope.package.address;
      }, function (error) {
        alert('No se pudo obtener la lista de comunas, intente denuevo mas tarde.');
      });
    };

    var loadAvailablesStarkenDestinies = function () {
      Commune.availableDestinies().then(function (data) {
        $scope.availableDestiniesStarken = data.availables;
      }, function (error) {
        alert('No se pudo obtener la lista de destinos disponibles para el courier Starken, intente denuevo mas tarde.');
      });
    };

    var loadCouriersBranchOffices = function () {
      CourierBranchOffice.all().then(function (data) {
        $scope.couriersBranchOffices = data;
        $scope.cbos = $scope.couriersBranchOffices;
        $scope.cbosByCouriers = CourierBranchOffice.byCouriers($scope.couriersBranchOffices);
        angular.element('select').select2();
      }, function (error) {
        alert('No se pudo obtener la lista de sucursales de los couriers, intente denuevo mas tarde.');
      });
    };

    var loadSkus = function () {
      Sku.by_client().then(function (data) {
        $scope.skus = data.client_skus;
      }, function (error) {
        alert('No se pudo obtener la lista de skus, intente denuevo mas tarde.');
      });
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
        case 'DHL':
        case 'Shippify':
        case 'CorreosChile':
        case 'Bluexpress':
          filtered = []
          $scope.package.courier_branch_office_id = 0;
          break;
        default:
          filtered = $scope.couriersBranchOffices;
          $scope.package.courier_branch_office_id = 0;
          break;
      };
      $scope.cbos = filtered;
      return filtered;
    };

    $scope.includes_tag = function () {
      console.log("entre a includes");
      var valid = false;
      if ($scope.package.includes("CCC")) {
        valid = true;
      };
      return valid;
    };

    $scope.loadPackages = function () { };

    $scope.loadInfo = function (hasFulfillment, notification, returnPackage) {
      $scope.notification = notification;
      $scope.hasFulfillment = hasFulfillment;
      if (returnPackage.id == null) {
        $scope.package = Package.new({ platform: 0 });
      }
      else{
        $scope.package = returnPackage;
        $scope.package.cellphone = parseInt(returnPackage.cellphone);
      }

      loadCommunes();
      loadCouriersBranchOffices();
      if ($scope.hasFulfillment) {
        loadSkus();
      }
    };

    $scope.addNewSkuToList = function (selectedSku) {
      if (selectedSku.id != undefined && selectedSku.qty != undefined) {
        var intoAll = _.find($scope.skus, function (obj) { return obj.name == selectedSku.name });
        var foundSku = _.find($scope.addedSkusList, function (obj) { return obj.name == selectedSku.name; });
        var sumQty = 0;
        if (foundSku != undefined) {
          sumQty = foundSku.qty + selectedSku.qty;
        } else {
          foundSku = angular.merge({}, selectedSku);
          sumQty = selectedSku.qty;
          $scope.package.withoutSkus = false;
        }
        if (intoAll.amount < sumQty || sumQty < 1) {
          alert('Sobrepasa el límite de stock para el sku: ' + foundSku.name);
        } else {
          $scope.removeSkuFromList(foundSku);
          foundSku.qty = sumQty;
          $scope.addedSkusList.push(angular.merge({}, foundSku));
        }
        resetSkuValues();
      }
    };

    $scope.removeSkuFromList = function (skuToRemove) {
      $scope.addedSkusList = _.reject($scope.addedSkusList, function (obj) {
        return obj.name == skuToRemove.name;
      });
    };

    $scope.massiveSkusLoad = function () {
      PackageService.lauchMassiveSkusModal($scope.skus).then(function (skus) {
        angular.forEach(skus, function (sku) {
          $scope.addNewSkuToList(sku);
        });
      }, function (error) {
        alert('No se han cargado skus', { type: 'warning' });
      });
    };

    $scope.activeSelect2 = function () {
      angular.element('select').select2();
    };

    $scope.checkoutPackage = function () {
      var address = $scope.package.address_attributes;
      $scope.package.address_attributes.full = address.street + ' ' + address.number + ', ' + angular.element('#communes option:selected').text();
      $scope.package = $scope.transformApproxSize($scope.package);
      $scope.courierForClient($scope.package, $scope.hasFulfillment).then(function () {
        PackageService.validate($scope.package, $scope.hasFulfillment, $scope.addedSkusList).then(function () {
          PackageService.lauchModal($scope.package, $scope.hasFulfillment, $scope.addedSkusList, 'PackageCheckoutModalInstanceController');
        }, function (data) {
          console.info(data.message);
          if (data.hasFulfillment && data.withoutSkus) {
            $scope.package.withoutSkus = data.withoutSkus;
          }
          alert(data.message);
          $scope.package.error = true;
        });
      }, function (error) {
        alert(error);
      });
    };

    $scope.courierForClient = function (model, hasFulfillment) {
      var defer = $q.defer();
      if ((model.fulfillment_delivery == '' || model.fulfillment_delivery == null) && model.without_courier) {
        defer.reject('Debes seleccionar tipo de despacho');
      } else if (model.without_courier) {
        model.courier_for_client = 'Fulfillment Delivery';
        model.destiny = model.fulfillment_delivery;
        model.courier_selected = true;
        defer.resolve();
      } else {
        if (hasFulfillment && !model.without_courier && model.courier_for_client == 'Fulfillment Delivery' && !$scope.destinations.includes(model.destiny)) {
          model.courier_for_client = '';
          model.destiny = '';
          model.courier_selected = false;
        }
        defer.resolve();
      }
      return defer.promise;
    };

    $scope.printLabels = function () {
      Package.printLabels().then(function (data) {
        window.open(data.link, '', 'width=1200,height=700');
      }, function (data) {
        console.error(data);
        var message = data.status == 404 ? data.message : 'Error al generar etiquetas, favor comunar a soporte.';
        alert(message);
      });
    };

    $scope.changeCourierBranchOffice = function (cbo) {
      if (cbo == null || cbo == undefined) {
        return false;
      }
      switch (cbo.courier_id) {
        case 1:
          $scope.package.courier_for_client = 'chilexpress';
          break;
        case 2:
          $scope.package.courier_for_client = 'starken';
          break;
        case 3:
          $scope.package.courier_for_client = 'correoschile';
          break;
        default:
          break;
      }
      $scope.package.courier_branch_office_id = cbo.id
      $scope.package.address_attributes = CourierBranchOffice.addressValues(cbo);
    };

    $scope.changeCommuneSelected = function () {
      $scope.cbos = CourierBranchOffice.byCommune(selectedDestinyCourierBO(), $scope.package.address_attributes.commune_id);
    };

    $scope.defaulAddress = function (model) {
      if (model.without_courier) {
        model.address_attributes = { street: 'Apoquindo', number: '4499', complement: 'Piso 13', commune_id: 308 };
      } else {
        model.address_attributes.street = '';
        model.address_attributes.number = '';
        model.address_attributes.complement = '';
        model.address_attributes.commune_id = 0;
      }
      setTimeout(function () { $scope.activeSelect2(); }, 500);
    };

    $scope.calculateInsurance = function (model) {
      if (model.with_purchase_insurance) {
        $scope.package.insurance = InsuranceService.new(model);
      } else {
        $scope.package.insurance = { maxSecure: 0, amount: 0, price: 0 };
      }
    };

    $scope.validateInsurance = function () {
      if ($scope.package.with_purchase_insurance == false) {
        $scope.package.insurance_attributes.extra = false;
      }
    };

    $scope.showCourierBranchOffices = function () {
      selectedDestinyCourierBO();
      if ($scope.package.destiny == "Chilexpress" || $scope.package.destiny == "Starken-Turbus") {
        setTimeout(function () {
          $('.branch-offices-list').select2();
        }, 10);
      }
    };

    $scope.transformApproxSize = function (package) {
      var size = {};
      switch (package.approx_size) {
        case 'Pequeño (10x10x10cm)':
          size = { length: 10, width: 10, height: 10, weight: 1 };
          break;
        case 'Mediano (30x30x30cm)':
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
      package.width = size.width;
      package.length = size.length;
      package.height = size.height;
      package.weight = size.weight;
      return package;
    };

  }]);
}).call(this);
