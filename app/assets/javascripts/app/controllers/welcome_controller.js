(function() {
  this.app.controller('WelcomeController', ['$scope', 'CollapsibleSidebarService', function($scope, CollapsibleSidebarService) {
    $scope.sidebar = false;
    $scope.collapse = CollapsibleSidebarService.collapsibleSidebar();

    $scope.toggleSidebar = function() {
      document.getElementById('app').classList.toggle('move-right');
      document.getElementById('app').classList.toggle('offscreen');
    };

    $scope.collapsibleSideBar = function() {
      if ($scope.collapse == undefined || $scope.collapse == null) {
        $scope.collapse = true      
      }
      $scope.collapse = !$scope.collapse;
      CollapsibleSidebarService.setCollapsibleSidebar($scope.collapse);
      $('#sidebar').toggleClass('active');
      $('.collapse.in').toggleClass('in');
      $('a[aria-expanded=true]').attr('aria-expanded', 'false');
    };

  }]);
}).call(this);
