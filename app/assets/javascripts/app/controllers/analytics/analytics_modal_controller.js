(function() {
  this.app.controller('AnalyticsModalInstanceController', ['$scope', '$uibModalInstance', 'Setting', function($scope, $uibModalInstance, Setting) {
    $scope.alerts = [];
    $scope.emails = [];
    $scope.setting = [];
    $scope.periods = [
      {id: 'week', name: 'Últimos 7 días'},
      {id: 'two_weeks', name: 'Últimos 15 días'},
      {id: 'month', name: 'Últimos 30 días'},
      {id: 'two_months', name: 'Últimos 60 días'}
    ];
    $scope.send_period = [
      {id: 'weekly', name: 'Enviar semanalmente'},
      {id: 'monthly', name: 'Enviar mensualmente'}
    ];
    $scope.send_day = []
    $scope.send_day.weekly = [
      {id: 'monday', name: 'Todos los lunes'},
      {id: 'friday', name: 'Todos los viernes'},
      {id: 'monday_friday', name: 'Todos los lunes y viernes'}
    ];
    $scope.send_day.monthly = [
      {id: 'first_day', name: 'Primer día del mes'}
    ];

    $scope.current = function(service_id) {
      Setting.current(service_id).then(function(data) {
        $scope.setting = data;
        emails = data.configuration.analytics.emails;
        if (emails.length != 0) {
          emails = _.map(emails.split(','), function (data, index) {
          return { id: (index + 1), email: data };
        });
      }
      $scope.emails['tags'] = emails;
      }, function(data) {
        console.error(data);
        $scope.alerts.push({ message: 'Ha ocurrido un error al intentar obtener tu configuracion de impresiones, favor comunicate a ayuda@shipit.cl', type: 'danger' });
      });
    };

    $scope.update = function() {
      emails = _.pluck($scope.emails.tags, 'email').join(', ');
      result = valid_setup($scope.setting.configuration.analytics, $scope.emails.tags);
      $scope.error = result.error;
      if (!result.valid) return;
      $scope.setting.configuration.analytics.emails = emails;
      Setting.update($scope.setting).then(function(data) {
        $scope.alerts.push({msg: 'Se han guardado los cambios.', type: 'success'});
        $scope.setting = data;
        $uibModalInstance.dismiss();
      }, function(data) {
        console.error(data);
        $scope.alerts.push({msg: 'Hubo un problema al intentar guardar los cambios.', type: 'danger'});
      });
    };

    $scope.cancel = function() {
      $uibModalInstance.dismiss();
    };

    $scope.closeAlert = function(index) {
      $scope.alerts = [];
    };
  }]);

  function valid_setup(data, emails) {
    var error = {};
    var valid = true;
    if (emails == '' || emails == undefined) {
      valid = false;
    }
    if (data.send_period == '' || data.send_period == undefined) {
      error.send_period = true;
      valid = false;
    }
    if (data.analytics_period == '' || data.analytics_period == undefined) {
      error.analytics_period = true;
      valid = false;
    }
    if (data.days == '' || data.days == undefined) {
      error.days = true;
      valid = false;
    }
    return { valid: valid, error: error };
  }
}).call(this);
