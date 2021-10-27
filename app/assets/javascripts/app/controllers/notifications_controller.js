(function() {
  this.app.controller('NotificationsController', ['$scope', '$uibModal', 'Notification', 'Sku', function($scope, $uibModal, Notification, Sku) {
    $scope.alerts = [];
    $scope.setting = {};
    $scope.company = {};
    $scope.skus = {};

    $scope.loadNotifications = function(companyId) {
      Notification.findBy(companyId).then(function(data) {
        $scope.setting = data.notification;
        $scope.company = data.company;
        $scope.company.logo = data.logo.replace('//s3', 'https://s3-us-west-2');
        console.info($scope.setting);
      }, function(error) {
        $scope.alerts.push({ message: 'Hubo un problema al intentar obtener tu Información, favor contactanos a ayuda@shipit.cl indicando tu problema.', type: 'danger' });
      });
    };

    $scope.updateNotifcation = function(notification, option) {
      if (option == 'email') {
        var reg =  /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i
        if (!reg.test(notification.configuration.notification.client.fulfillment.email)) {
          notification.configuration.notification.client.fulfillment.email = '';
          $scope.alerts.push({ message: '¡Debes ingresar un correo valido!.', type: 'danger' });
          return;
        }
      }

      Notification.update(notification).then(function(data) {
        $scope.alerts.push({ message: '¡Notificacion Actualizada!', type: 'success'});
        $scope.setting = data.notification;
      }, function(error) {
        $scope.alerts.push({ message: 'Hubo un problema al intentar actualizar la configuración, favor contactanos a ayuda@shipit.cl indicando tu problema.', type: 'danger' });
      });
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.lunchBaseFormatModal = function(company) {
      Notification.baseFormatModal(company).then(function(data) {
        $scope.company = data;
        $scope.company.logo = data.logo.replace('//s3', 'https://s3-us-west-2');
      }, function(error) {
        if (error != 'backdrop click') {
          console.error(error);
          $scope.alerts.push({ message: 'Hubo un problema al intentar actualizar la configuración, favor contactanos a ayuda@shipit.cl indicando tu problema.', type: 'danger' });
        } else {
          $scope.loadNotifications($scope.company.id);
          $scope.alerts.push({ message: 'Has cancelado la edición del formato base.', type: 'info' });
        }
      });
    };

    $scope.loadModalSkus = function() {
      Sku.by_client().then(function(data) {
        Notification.skusModal(data.client_skus);
      }, function(error) {
        $scope.alerts.push({msg: 'Ha ocurrido un error, favor notificar a ayuda@shipit.cl indicando lo sucedido.', type: 'danger'});
      });
    };
  }]).
  controller('EmailBaseFormatController', ['$scope', '$uibModalInstance', '$timeout', 'Company', 'company', function($scope, $uibModalInstance, $timeout, Company, company) {
    $scope.alerts = [];
    $scope.company = company;

    $scope.loadLogo = function(url, local) {
      angular.element('img').attr('src', (url == local ? local : url.replace('//s3', 'https://s3-us-west-2')));
    };

    $scope.activeColorPicker = function() {
      angular.element('#colorpicker-header').colorpicker();
      angular.element('#colorpicker-footer').colorpicker();
      angular.element('#colorpicker-font').colorpicker();
    };

    $scope.updateEmailPreference = function(company) {
      Company.updateEmailPreference(company).then(function(data) {
        $scope.alerts.push({ message: 'Informacion actualizada', type: 'success'});
        $scope.company = data.company;
        $timeout(function () { window.location.reload(true) }, 1500);
      }, function(error) {
        $scope.alerts.push({ message: 'Hubo un problema al intentar actualizar la configuración, favor contactanos a ayuda@shipit.cl indicando tu problema.', type: 'danger' });
        $timeout(function () { $uibModalInstance.dismiss(error); }, 3000);
      });
    };

    $scope.close = function() {
      $uibModalInstance.dismiss('backdrop click');
    };

  }]).
  controller('SecurityStockController', ['$scope', '$uibModalInstance', '$timeout', 'skus', 'Sku', function($scope, $uibModalInstance, $timeout, skus, Sku) {
    $scope.skus = skus;
    $scope.alerts = [];

    $scope.validateNumber = function(model, value, name) {
      if (value !== undefined) {
        typeof value === 'number' ? value = value.toString() : null;
        model[name] = value = value.replace(/[^0-9\.]+/g, '').replace(/,/g, '');
        if (value.split('.').length > 2) {
          model[name] = value.substring(0, (value.length - 1));
        }
      }
    };

    $scope.updateMinStock = function(skus) {
      Sku.updateMinStock(skus).then(function(data) {
        $scope.alerts.push({ message: "SKU'S Actualizados, ahora te llegara una alerta cuando cada SKU llege al monto indicado", type: 'success' });
        $timeout(function() {
          $scope.cancel();
        }, 3000)
      }, function(error) {
        $scope.alerts.push({ message: 'Error en el proceso, favor contactar al área de desarrollo de Shipit.', type: 'danger' });
      });
    };

    $scope.cancel = function() {
      $uibModalInstance.dismiss();
    };

  }]);
}).call(this);
