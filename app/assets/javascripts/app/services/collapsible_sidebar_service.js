(function() {
  this.app.service('CollapsibleSidebarService', ['$localStorage', '$q', function($localStorage, $q) {
    return {
        setCollapsibleSidebar: function(collapsible) {
          $localStorage.collapsible = collapsible;
        },
        collapsibleSidebar: function() {
          return $localStorage.collapsible;
        },
        restart: function() {
          this.setCollapsibleSidebar({});
          return {};
        }
      }
  }]);
}).call(this);
