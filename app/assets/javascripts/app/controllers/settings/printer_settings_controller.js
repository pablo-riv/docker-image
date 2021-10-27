(function () {
  this.app.controller('PrinterSettingsController', ['$scope', '$timeout', 'Setting', function ($scope, $timeout, Setting) {
    $scope.setting = {};
    $scope.alerts = [];
    $scope.formatAvailables = [];
    $scope.printer = {};
    $scope.kindOfPrints = [{ id: 1, name: 'Descargar', system: 'download' }, { id: 1, name: 'Impresión Cloud', system: 'print_node' }];
    $scope.packagesLabelSizes = [{ id: 1, name: '4x2', system: '4x2' }, { id: 2, name: '4x4', system: '4x4' }, { id: 3, name: '4x6', system: '4x6' }];

    $scope.current = function (service_id) {
      Setting.current(service_id).then(function (data) {
        $scope.setting = data;
        try {
          $scope.selectProvider();
          $scope.printer = Setting.printer($scope.setting.configuration.printers);
          $scope.formatAvailables = $scope.loadFormatAvaliables(data.configuration.printers.available_to_add_providers, data.configuration.printers.formats);
        } catch (error) {
          $scope.alerts.push({ msg: 'No tienes formatos disponibles, favor comunicate con ayuda@shipit.cl', type: 'danger' });
          $scope.formatAvailables = [];
        }
        $timeout(function () { angular.element('#format').select2(); }, 500);
      }, function (data) {
        console.error(data);
        $scope.alerts.push({ message: 'Ha ocurrido un error al intentar obtener tu configuracion de impresiones, favor comunicate a ayuda@shipit.cl', type: 'danger' });
      });
    };

    $scope.loadFormatAvaliables = function (avaliableToAddProviders, formats) {
      if (avaliableToAddProviders) {
        return _.filter(formats, function (data) { return !['avery', 'epl'].includes(data.name) });
      } else {
        return _.filter(formats, function (data) { return data.name == 'avery' });
      };
    };

    $scope.update = function (format) {
      if ($scope.setting.configuration.printers.available_to_add_providers && (format.id_printer == '' || format.id_printer == void (0)) && $scope.setting.configuration.printers.kind_of_print != 'download') {
        format.active = false;
        $scope.setting.configuration.printers.availables[0].active = false;
        alert('Debes ingresar un ID de impresora para poder imprimir las etiquetas');
        return false;
      }
      $scope.selectProvider();
      $scope.setting = Setting.injectConfiguration($scope.setting, format);
      Setting.update($scope.setting).then(function (data) {
        $scope.alerts.push({ msg: 'Se han guardado los cambios.', type: 'success' });
        $scope.setting = data;
      }, function (data) {
        console.error(data);
        $scope.alerts.push({ msg: 'Hubo un problema al intentar guardar los cambios.', type: 'danger' });
      });
    };

    $scope.closeAlert = function (index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.translatePrint = function(format) {
      var kind = $scope.kindOfPrints.filter(function (data) {  if (data.system == format) return data.name; });
      return kind[0].name;
    };

    $scope.selectProvider = function(kind) {
      if (kind == 'download') {
        return 'WEB BROWSER';
      } else {
        return 'PRINT NODE';
      }
    };

    $scope.updatePrinter = function (kind) {
      $scope.printer.kind_of_print = kind;
    };

    $scope.updateLabelSize = function (kind) {
      $scope.printer.label_package_size = kind;
      $scope.update($scope.formatAvailables[0]);
    };

  }]);
}).call(this);
