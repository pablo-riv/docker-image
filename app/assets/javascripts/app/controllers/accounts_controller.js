(function() {
  this.app.controller('AccountsController', ['$scope', 'Company', function($scope, Company) {
    $scope.account = {};
    $scope.loadAccount = function(account) {
      angular.extend(account, { company: account.entity_specific });
      delete account.entity_specific;
      $scope.account = account;
    };

    $scope.humanServiceName = function(name) {
      return Company.serviceName(name);
    };
  }]);
}).call(this);
