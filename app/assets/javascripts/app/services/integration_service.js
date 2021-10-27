(function() {
  this.app.service('IntegrationService', ['$uibModal', '$q', function ($uibModal, $q) {
    return {
      launchModal: function(hasFulfillment, rows) {
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'integrationCheckout.html',
          controller: 'IntegrationCheckoutModalInstanceController',
          size: 'lg',
          resolve: {
            hasFulfillment: function() {
              return hasFulfillment;
            },
            rows: function() {
              return rows;
            }
          }
        });
        modal.result.then(function() {}, function(error) {});
      },
      launchEditOrderModal: function(hasFulfillment, order, communes, cbos) {
        var defer = $q.defer();
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'editOrder.html',
          controller: 'EditOrderModalInstanceController',
          size: 'lg',
          resolve: {
            hasFulfillment: function() {
              return hasFulfillment;
            },
            order: function() {
              return order;
            },
            communes: function() {
              return communes;
            },
            cbos: function() {
              return cbos;
            }
          }
        });
        modal.result.then(function(_order) {
          defer.resolve(_order);
        }, function(error) {
          defer.reject(error)
        });

        return defer.promise;
      },
      launchEditOrderFormatConfigModal: function(seller, orders) {
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'editOrderFormatConfigModal.html',
          controller: 'EditOrderFormatConfigModalInstanceController',
          size: 'lg',
          resolve: {
            seller: function() {
              return seller;
            },
            orders: function() {
              return orders;
            }
          }
        });
        modal.result.then(function() {}, function(error) {});
      }
    };
  }]);
}).call(this);