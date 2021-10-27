(function() {
  this.app.controller('HelpShowController', ['$scope', '$sce', '$uibModalInstance', 'Support', 'SupportService', 'supportId', function($scope, $sce, $uibModalInstance, Support, SupportService, supportId) {
    $scope.support = {};
    $scope.alerts = [];
    $scope.supportId = supportId;

    $scope.init = function() {
      Support.find(supportId).then(function(data) {
        $scope.support = data.support;
      }, function(data) {
        $scope.alerts.push({ message: 'Ha ocurrido un error al intentar obtener el ticket '+ supportId +', favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
      });
    };

    $scope.init();

    $scope.getStatusName = function(status) {
      return SupportService.getStatusName(status);
    };

    $scope.getClassifyStatus = function(status) {
      return SupportService.getClassifyStatus(status);
    };

    $scope.getPriority = function(priority) {
      return SupportService.getPriority(priority);
    };

    $scope.getAgent = function(id) {
      return 'Soporte Shipit';
    };

    $scope.sanitizeMessage = function(message) {
      return $sce.trustAsHtml(message.message);
    };

    $scope.getKlass = function(message) {
      if (message.user == 'end_user') {
        message.positionKlass = 'pull-right';
        message.textKlass = 'text-right';
      } else if (message.user == 'admin') {
        message.positionKlass = "pull-left";
        message.textKlass = "text-left";
      } else {
        message.positionKlass = 'pull-right';
        message.textKlass = 'text-right';
      }
    };

    $scope.cancel = function() {
      $uibModalInstance.dismiss();
    };

    $scope.submitMessage = function(keyEvent, message) {
      if (keyEvent.which == 13 && message){
        $scope.inputMessage = "";
        Support.submitMessage(message, $scope.support.provider_id).then(function(data) {
          $scope.support.messages = data.messages;
        }, function(data) {
          $scope.alerts.push({message: "No se pudo enviar tu mensaje: "+message+" Por favor responde a este hilo directamente desde tu correo electrónico", type: 'danger'});
        });
      };
    };
  }]);
}).call(this);
