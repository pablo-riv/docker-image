(function() {
  this.app.controller('HelpCreateController', ['$scope', '$uibModalInstance', '$timeout', 'Support', 'SupportService', 'package', function($scope, $uibModalInstance, $timeout, Support, SupportService, package) {
    $scope.support = Support.new(package);
    $scope.alerts = [];
    $scope.package = package;
    $scope.subjects = SupportService.subjects();
    $scope.otherSubjects = [];
    $scope.loading = false;

    $scope.create = function(support) {
      var errors = validateSupport(support);
      if (errors.length > 0) {
        sendMessages(errors);
      } else {
        $scope.loading = true;
        Support.create(support).then(function(data) {
          $scope.alerts.push({ message: '¡Ticket creado, nos pondremos en contacto!', type: 'success' });
        }, function() {
          $scope.alerts.push({ message: 'Ha ocurrido un error al intentar crear un ticket, favor enviar un correo a ayuda@shipit.cl.', type: 'danger' });
          $timeout(function() { $scope.cancel(); }, 5000);
        });
      }
    };

    $scope.cancel = function() {
      $uibModalInstance.dismiss();
    };

    var validateSupport = function(support) {
      return SupportService.validate(support);
    };

    var sendMessages = function(errors) {
      angular.forEach(errors, function(value, index) {
        if (value.message != '') {
          $scope.alerts.push({ message: value.message, type: value.type });
        }
      });
    };

    $scope.activateSelect2 = function() {
      angular.element('select').select2({ width: '100%' });
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.loadOtherSubjects = function(subject) {
      try {
        var originalSubject = _.findWhere(SupportService.subjects(), { 'subject': subject });
        $scope.otherSubjects = _.where(SupportService.otherSubjects(), { 'id': originalSubject.id });
        if ([2,3,5,6,9].includes(originalSubject.id)) {
          $scope.support.need_package_data = true;
        } else {
          $scope.support.need_package_data = false;
        }
      } catch (e) {
        $scope.otherSubjects = [];
        $scope.support.need_package_data = false;
      }
    };

  }]);
}).call(this);
