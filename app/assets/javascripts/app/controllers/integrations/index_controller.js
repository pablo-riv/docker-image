(function() {
  this.app.controller('IndexIntegrationsController', ['$scope', '$uibModal', 'Order', 'Commune', 'Setting', 'CourierBranchOffice', 'IntegrationService', 'PackageService', function($scope, $uibModal, Order, Commune, Setting, CourierBranchOffice, IntegrationService, PackageService) {
    $scope.alerts = [];
    $scope.loading = false;
    $scope.hasFulfillment = false;
    $scope.checkOrders = false;
    $scope.api2cartClient = false;
    $scope.woocommerceOrders = [];
    $scope.prestashopOrders = [];
    $scope.filters = ['Todos'];
    $scope.filter_type = 'Todos';
    // $scope.alerts.push({ msg: 'Tip: Recuerda presionar el botón Actualizar lista si no ves órdenes en la lista', type: 'info' });

    App.integration_messages = App.cable.subscriptions.create('IntegrationChannel', {
      connected: function(data) {
        console.log('connected');
        return false;
      },
      disconnected: function(data) {
        console.log('disconnected');
        return false;
      },
      received: function(data) {
        $scope.loading = data.message;
        if (!data.message) {
          loadOrders();
        }
        console.log(data);
        return false;
      }
    });

    $scope.setDate = function (fromDate, toDate) {
      $scope.search = {
        from_date: fromDate,
        to_date: toDate,
        per: 50,
        filter: 'Todos',
        page: 1
      };
    };

    var loadOrders = function() {
      $scope.filter_type = $scope.search.filter;
      Order.all($scope.search).then(function(data) {
        $scope.newOrder = data.newOnes;
        $scope.allOrder = _.union(data.newOnes, data.archivedOnes);
        $scope.archivedOrder = data.archivedOnes;
        $scope.orders = _.union(data.newOnes, data.archivedOnes);
        $scope.totalOrders = data.totalOrdersCount;
        $scope.filters = _.uniq($scope.filters.concat(data.filter));
        angular.forEach($scope.orders, function(order) {
          if (order.seller == 'woocommerce' || order.seller == 'prestashop') {
            $scope.api2cartClient = true;
            switch (order.seller) {
              case 'woocommerce':
                $scope.woocommerceOrders.push(order);
                break;
              case 'prestashop':
                $scope.prestashopOrders.push(order);
                break;
            }
          }
        });
        $scope.skus = data.skus;
        $scope.hasFulfillment = data.hasFulfillment;
        setTimeout(function() {
          angular.element('select').select2();
        }, 1000);
      },
      function(data) {
        console.error(data);
      });
    };

    var changeOrdersToSelected = function(orders) {
      angular.forEach(orders, function(order) {
        order.selected = $scope.checkOrders;
      });
    };

    var loadCouriersBranchOffices = function() {
      CourierBranchOffice.all().then(function(data) {
        var cbosByCouriers = CourierBranchOffice.byCouriers(data);
        $scope.cbos = cbosByCouriers;
        angular.element('select').select2();
      }, function(error) {
        alert('No se pudo obtener la lista de sucursales de los couriers, intente de nuevo más tarde.');
      });
    };

    var sendToArchive = function(order, archive) {
      msg = archive ? 'archivada' : 'desarchivada';
      Order.archive(order._id.$oid, archive).then(function(data) {
        order.archive = true;
        $scope.alerts.push({ msg: 'Órden ' + order.order_id + ' ' + msg, type: 'success' });
      }, function(error) {
        $scope.alerts.push({ msg: 'La órden no quedó ' + msg, type: 'error' });
      })
    };

    var isDownloading = function() {
      Order.isDownloading().then(function(model) {
        $scope.lastDownloadTime = model.data.last_time;
        $scope.loading = model.data.downloading;
      }, function(error) {
        $scope.alertMessageCounter += 1;
        if ($scope.alertMessageCounter < 1) {
          $scope.alerts.push({ msg: 'No pudimos determinar si habia una descarga en cola', type: 'error' });
        }
      });
    };


    $scope.selectAllOrders = function(check, all) {
      $scope.checkOrders = check;
      if (all == true) {
        changeOrdersToSelected($scope.newOrder);
      } else {
        if (all == false) {
          changeOrdersToSelected($scope.archivedOrder);
        } else {
          changeOrdersToSelected($scope.newOrder);
          changeOrdersToSelected($scope.archivedOrder);
        }
      }
    };

    $scope.getOrders = function() {
      isDownloading();

      Commune.all('').then(function(data) {
        $scope.communes = data.communes;
      }, function(data) {
        console.error(data);
      });

      loadOrders();

      Setting.sellersIntegrated().then(function(data) {
        $scope.integratedSellers = data;
      }, function(error) {
        console.error(error)
      });

      loadCouriersBranchOffices();
    };

    $scope.checkoutSelectedOrders = function() {
      var elements = _.filter($scope.orders, function(order) { return order.selected == true; });
      var rows = Order.getSkusStock($scope.hasFulfillment, $scope.skus, elements);
      IntegrationService.launchModal($scope.hasFulfillment, PackageService.markCourierSelected(rows));
    };

    $scope.archiveSelected = function(archive) {
      var elements = _.filter($scope.orders, function(order) { return order.selected == true; });
      angular.forEach(elements, function(e) {
        sendToArchive(e, archive);
      });
      setTimeout(window.location.reload(), 2000);
    };

    $scope.showEditModal = function(order) {
      IntegrationService.launchEditOrderModal($scope.hasFulfillment, order, $scope.communes, $scope.cbos).then(function(_order) {
        angular.extend($scope.orders, _order);
      }, function(_error) {
          $scope.alerts.push({ msg: 'Lo sentimos, no pudimos actualizar tu orden, favor verificar los datos ingresados.', type: 'danger' });
      });
    };

    $scope.archive = function(order, archive) {
      sendToArchive(order, archive);
      setTimeout(window.location.reload(), 2000);
    }

    $scope.openApi2CartConfig = function(seller) {
      if ($scope.api2cartClient) {
        var order = {};
        switch (seller) {
          case 'woocommerce':
            orders = $scope.woocommerceOrders
            break;
          case 'prestashop':
            orders = $scope.prestashopOrders;
            break;
        };
        IntegrationService.launchEditOrderFormatConfigModal(seller, orders);
      }
    };

    $scope.pageChanged = function () {
      $scope.getOrders();
    };

    $scope.downloadSellerOrders = function() {
      $scope.loading = true;
      Order.sync().then(function() {
        // $scope.alerts.push({ msg: 'Estamos sincronizando tus órdenes', type: 'info' });
        $scope.loading = true;
      }, function(error) {
        $scope.alerts.push({ msg: 'Lo sentimos, no pudimos sincronizar tus órdenes', type: 'danger' });
      })
    };

    $scope.closeAlert = function(index) {
      $scope.alerts.splice(index, 1);
    };

    $scope.lunchXlsxOrderModal = function() {
      var modal = $uibModal.open({
        animation: true,
        ariaLabelledBy: 'modal-title',
        ariaDescribedBy: 'modal-body',
        templateUrl: 'modal_xlsx_create.html',
        controller: 'OrderXlsxCreateModalController',
        size: 'xl'
      });
      modal.result.then(function (orders) {
        var elements = orders;
        var rows = Order.getSkusStock($scope.hasFulfillment, $scope.skus, elements);
        IntegrationService.launchModal($scope.hasFulfillment, PackageService.markCourierSelected(rows));
      }, function (error) {
        if (error !== 'backdrop click') {
          window.location.reload(true);
        }
      });
    };

  }]);
}).call(this);