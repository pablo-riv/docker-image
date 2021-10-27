(function () {
  this.app.controller('LabelsIndexController', ['$scope', 'Label', 'Setting', 'CourierService', 'Commune', '$uibModal', function ($scope, Label, Setting, CourierService, Commune, $uibModal) {
    $scope.packages = [];
    $scope.setting = {};
    $scope.alerts = [];
    $scope.couriers = [];
    $scope.sellers = [];
    $scope.payables = [
      { id: 1, name: 'Todos los envíos', system: 'all' },
      { id: 2, name: 'Cargados a la factura', system: false },
      { id: 1, name: 'Por pagar en destino', system: true },
    ];
    $scope.destinies = [
      { id: 1, name: 'Todos los envíos', system: 'all' },
      { id: 2, name: 'Domicilio', system: 'domicilio' },
      { id: 1, name: 'Sucursal', system: 'sucursal' },
    ];
    $scope.helpMessage = '';
    $scope.countPackages = 0;

    $scope.setDate = function(from, to) {
      var couriers = CourierService.oldCouriers();
      couriers.shift();
      couriers.unshift({ id: 0, name: 'Todos los Couriers', system: 'all' });
      $scope.couriers = couriers;
      loadCommunes();
      $scope.search = {
        from: from,
        to: to,
        per: 200,
        page: 1,
        reference: '',
        courier: $scope.couriers[0].system,
        commune: $scope.couriers[0].system,
        seller: '',
        payable: $scope.payables[0].system,
        destiny: $scope.destinies[0].system
      };
      $scope.search.selected_courier = $scope.couriers[0];
      $scope.search.selected_payable = $scope.payables[0];
      $scope.search.selected_destiny = $scope.destinies[0];
    };

    $scope.getLabels = function () {
      Label.todayWithoutChecks($scope.search).then(function (data) {
        $scope.packages = data.packages;
        $scope.sellers = decorateIntegration(data.integration);
        $scope.search.selected_seller = $scope.sellers[0];
        $scope.totalLabels = data.total_packages;
        $scope.printer = Setting.printer(data.setting.configuration.printers);
        if ($scope.printer.format == 'zpl' && $scope.printer.kind_of_print == 'download') {
          $scope.helpMessage = '¡Solo podras imprimir los pedidos que tengan Nº de seguimiento asignado y en estado EN PREPARACIÓN!\nSi necesitas imprimir y no tienes todos los pedidos con Nº de seguimiento, contactanos a nuestro canal de ayuda a través de nuestro correo ayuda@shipit.cl';
        } else if ($scope.printer.format == 'zpl') {
          $scope.helpMessage = '¡Solo podras imprimir los pedidos que tengan Nº de seguimiento asignado y en estado EN PREPARACIÓN!\nSi necesitas imprimir y no tienes todos los pedidos Nº de seguimiento, contactanos a nuestro canal de ayuda a través de nuestro correo ayuda@shipit.cl';
        } else {
          $scope.helpMessage = '¡Solo podras imprimir los pedidos que tengan el estado EN PREPARACiÓN!\nSi tienes problemas para generar las etiquetas contactanos a nuestro canal de ayuda, a través, de nuestro correo ayuda@shipit.cl';
        }
        setTimeout(function () { angular.element('select').select2(); }, 1000);
      }, function (error) {
        console.error(error);
        $scope.alerts.push({ message: 'Ha ocurrido un error al intentar obtener los envíos del dia, favor comunicate a ayuda@shipit.cl', type: 'danger' });
      });
    };

    $scope.printJob = function() {
      Label.printerJob().then(function(_resolve) {
        $scope.alerts.push({ message: 'Se han agregado las etiquetas a la cola de impresión.', type: 'success' });
      }, function(_reject) {
        console.error(_reject);
      });
    };

    $scope.printLabels = function() {
      var packages = _.where($scope.packages, { check: true });
      if (packages.length < 1) {
        $scope.alerts.push({ message: 'Debes seleccionar las etiqueta a imprimir', type: 'danger' });
      } else {
        Label.create(packages).then(function (data) {
          if ($scope.printer.format == 'zpl' && $scope.printer.kind_of_print == 'print_node') {
            $scope.alerts.push({ message: 'Se han agregado las etiquetas a la cola de impresión.', type: 'success' });
          } else {
            $scope.alerts.push({ message: 'PDF con etiquetas generadas.', type: 'success' });
            window.open(data.link, '', 'width=1200,height=700');
          }
          setTimeout(function () { window.location.reload(true) }, 4000);
          $scope.countPackages = 0;
        }, function (data) {
          $scope.alerts.push({ message: 'No se han impreso las etiquetas favor revisar.', type: 'danger' });
        });
      }
    };

    $scope.print = function(id) {
      Label.create([{ id: id }]).then(function(data) {
        if ($scope.printer.format == 'zpl' && $scope.printer.kind_of_print == 'print_node') {
          $scope.alerts.push({ message: 'Se han agregado las etiquetas a la cola de impresión.', type: 'success' });
        } else {
          $scope.alerts.push({ message: 'PDF con etiquetas generadas.', type: 'success' });
          window.open(data.link, '', 'width=1200,height=700');
        }
      }, function(data) {
          $scope.alerts.push({ message: 'No se han impreso las etiquetas favor revisar.', type: 'danger' });
      });
    };

    $scope.search = function(search) {
      $scope.clearAll();
      Label.search(search).then(function(data) {
        $scope.packages = data.packages;
      }, function(error) {
        $scope.alerts.push({ message: 'No se han encontrado resultados.', type: 'danger' });
      });
    };

    $scope.countPackageChecked = function () {
      return _.where($scope.packages, { check: true }).length;
    };

    $scope.addAll = function () {
      if ($scope.packages.length > 0) {
        if (angular.element('#all').prop('checked')) {
          for (var index = 0; index < $scope.packages.length; index++) {
            $scope.packages[index]['check'] = true;
          }
          $scope.countPackages = $scope.packages.length;
        } else {
          $scope.clearAll();
        }
      }
    };

    $scope.clearAll = function () {
      if ($scope.packages.length > 0) {
        for (var index = 0; index < $scope.packages.length; index++) {
          $scope.packages[index]['check'] = false;
        }
        $scope.countPackages = 0;
        angular.element('#all').prop('checked', false);
      }
    };

    $scope.count = function(check) {
      if (check) {
        $scope.countPackages += 1;
      } else {
        $scope.countPackages -= 1;
      }
    };

    $scope.closeAlert = function (index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.statusColor = function(averyPrinted) {
      return averyPrinted ? 'delivery' : 'not-printed';
    };

    $scope.pageChanged = function () {
      $scope.getLabels();
    };

    $scope.getIcon = function (courier) {
      return ['', undefined].includes(courier) ? '' : CourierService.getIcon(courier);
    };

    var loadCommunes = function () {
      Commune.all('').then(function (data) {
        var communes = data.communes;
        communes.unshift({ id: 'all', name: 'Todas las Comunas', system: 'all'});
        $scope.communes = communes;
        $scope.search.selected_commune = $scope.communes[0];
        angular.element('select').select2();
      }, function (error) {
        alert('No se pudo obtener la lista de comunas, intente denuevo mas tarde.');
      });
    };

    $scope.setSelected = function (selected, value) {
      $scope.search[selected] = selected == 'commune' ? value.id : value.system;
    };

    var decorateIntegration = function (sellers) {
      sellers.unshift('Todos los canales de venta');
      return sellers.map(function (value, index) {
        return { id: index, name: value, system: index == 0 ? 'all' : value };
      });
    };

    $scope.lunchXlsxOrderModal = function() {
      var modal = $uibModal.open({
        animation: true,
        ariaLabelledBy: 'modal-title',
        ariaDescribedBy: 'modal-body',
        templateUrl: 'order_xlsx_modal.html',
        controller: 'OrderXlsxModalController',
        size: 'lg'
      });
      modal.result.then(function (packages) {
        Label.create(packages).then(function (data) {
          if ($scope.printer.format == 'zpl' && $scope.printer.kind_of_print == 'print_node') {
            $scope.alerts.push({ message: 'Se han agregado las etiquetas a la cola de impresión.', type: 'success' });
          } else {
            $scope.alerts.push({ message: 'PDF con etiquetas generadas.', type: 'success' });
            window.open(data.link, '', 'width=1200,height=700');
          }
          setTimeout(function () { window.location.reload(true) }, 4000);
          $scope.countPackages = 0;
        }, function (data) {
            $scope.alerts.push({ message: 'No se han impreso las etiquetas favor revisar.', type: 'danger' });
        });

      }, function(error) {
          if (error !== 'backdrop click') {
            window.location.reload(true);
          }
      });
    };

  }]);
}).call(this);
