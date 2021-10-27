(function () {
  this.app.controller('HelpIndexController', ['$scope', '$timeout', 'Support', 'SupportService', 'Package', function($scope, $timeout, Support, SupportService, Package) {
    $scope.supports = [];
    $scope.alerts = [];

    $scope.init = function(status) {
      $scope.activePane = status;
      Support.all(status).then(function(data) {
        $scope.supports = data.supports;
      }, function(data) {
        $scope.alerts.push({ message: 'Ha ocurrido un error al intentar obtener tus tickes, favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
      });
    };

    $scope.classifySupport = function(priority) {
      return SupportService.classifySupport(priority);
    };

    $scope.getPriority = function(priority) {
      return SupportService.getPriority(priority);
    };

    $scope.getKind = function(kind) {
      return SupportService.getKind(kind);
    };

    $scope.getAgent = function(agent) {
      return SupportService.getAgent(agent);
    };

    $scope.showDetail = function(id) {
      SupportService.showDetail(id).then(function(data) { }, function(error) { });
    };

    $scope.create = function(id, reference) {
      Package.find(id).then(function(data) {
        SupportService.createModal(data.package).then(function(data) {
          $scope.alerts.push({ message: '¡Ticket creado, nos pondremos en contacto!', type: 'success' });
        }, function(error) {
          if (error != undefined) {
            $scope.alerts.push({ message: 'Ha ocurrido un error al comunicarnos con zendesk, favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
          }
        });
      }, function(data) {
        if (error != undefined) {
          $scope.alerts.push({ message: 'Ha ocurrido un error al intentar obtener los datos del envío, favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
        }
      });
    };

    $scope.lunchTicketModal = function() {
      SupportService.createModal({id: '', reference: '', tracking_number: ''}).then(function(data) {
        $scope.alerts.push({ message: '¡Ticket creado, nos pondremos en contacto!', type: 'success' });
      }, function(error) {
        if (error != undefined) {
          $scope.alerts.push({ message: 'Ha ocurrido un error al comunicarnos con zendesk, favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
        }
      });
    };

    $scope.syncronize = function() {
      $scope.alerts.push({ message: 'Enviando solicitud de sincronizacion de tickets.......', type: 'info' });
      $timeout(function() {
        Support.syncronize().then(function(data) {
          $scope.alerts.push({ message: data.message, type: 'success' });
          $timeout(function() { window.location.reload(true); }, 3000);
        }, function(error) {
          $scope.alerts.push({ message: 'Ha ocurrido un error al intentar sincronizar los tickets, favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
        });
      }, 2000);
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

  }]);
}).call(this);
