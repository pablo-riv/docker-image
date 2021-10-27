(function() {
  this.app.controller('FulfillmentController', ['$scope', '$uibModal', 'Fulfillment', function($scope, $uibModal, Fulfillment) {
    $scope.alerts = [];
    $scope.page = 1;
    $scope.reverse = true;
    $scope.property = '';

    $scope.index = function(type, inventoryType, page) {
      Fulfillment.history(inventoryType, page).then(function(data) {
        loadByType(type, data);
      }, function(data) {
        $scope.alerts.push({ type: 'danger', message: 'Ha ocurrido un error, favor contactar a ayuda@shipit.cl indicando lo sucedido.' });
      });
    };

    $scope.inventoryType = function(type) {
      switch (type) {
        case 1:
          return 'Egreso';
          break;
        case 2:
          return 'Ingreso';
          break;
        case 3:
          return 'Retiro';
          break;
      };
    };

    var loadByType = function(type,  data) {
      switch (type) {
        case 'outs':
          $scope.outs = data.activities;
          break;
        case 'inventories':
          $scope.inventories = data.skus;
          break;
        case 'receipts':
          $scope.receipts = data.activities;
          break;
        default:
          break;
      }
      $scope.company = data.company;
    };

    $scope.wsAlert = function(sku){
      return (sku.amount > sku.ws_amount && sku.ws_updated_at != null) ? 'route' : '';
    };

    $scope.changeMovements = function(type, inventoryType, page) {
      $scope.page = $scope.paginate(page);
      $scope.index(type, inventoryType, $scope.page);
    };

    $scope.paginate = function (page) {
      if (page == -1 || page == undefined || page == null) {
        $scope.page = 1;
      } else {
        $scope.page = $scope.page + page;
      }
      return $scope.page;
    };

    $scope.sort = function(property) {
      $scope.reverse = ($scope.property === property) ? !$scope.reverse : false;
      $scope.property = property;
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.sumOrders = function(model) {
      model.orders = _.reduce(_.pluck(model.inventory_activity_orders, 'amount'), function(memo, num){ return memo + num; }, 0);
    };

    $scope.shortDescription = function(description) {
      return description.slice(0, description.length - 22);
    };
  }]);
}).call(this);
