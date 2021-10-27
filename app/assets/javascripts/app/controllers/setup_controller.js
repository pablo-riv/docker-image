(function() {
  this.app.controller('SetupController', ['$scope', 'Company', 'Account', 'BranchOffice', function($scope, Company, Account, BranchOffice) {
    $scope.account = { };
    $scope.communes = [];
    $scope.parkings = [
      {name: 'En la calle'},
      {name: 'De visita'},
      {name: 'Pagado (tendrá un recargo según el costo)'},
      {name: 'No hay estacionamiento (llamar antes para coordinar retiro)'}
    ];
    $scope.loadAccount = function(account, communes) {
      $scope.account = Account.init(account);
      $scope.communes = communes;
      // console.info($scope.account.company.branch_office.get_to_parking);
    };

    $scope.humanServiceName = function(name) {
      return Company.serviceName(name);
    };

    $scope.updateCompanySetup = function(account) {
      account.company.email_contact = _.pluck(account.tags, 'email').join(', ');
      var result = Account.validSetup(account);
      $scope.error = result.error;
      if (result.valid) {
        Company.setup(account).then(function(data) {
          window.location.href = '/dashboard';
        }, function(data) {
          alert('Hubo un error, favor contactar con soporte');
        });
      } else {
        alert('Favor revisar datos ingresados!');
      }
    };

  }]);
}).call(this);
