(function() {
  this.app.controller('ApiController', ['$scope', function($scope) {

    $scope.loadSandbox = function(active) {
      $scope.activeSandbox = active;
    };

  }]);
}).call(this);
