(function(){
  this.app.controller('SettingsController', ['$scope', '$uibModal', 'Setting', 'Sku', function ($scope, $uibModal, Setting, Sku){
    $scope.alerts = [];
    $scope.settings = [];
    $scope.fullit = {};
    $scope.sellers = [];
    $scope.algorithms = [{id: 2, name: "Más económico con despacho igual o menos a X días"}];
    $scope.displayAlgorithmDays = false;
    $scope.current = function (service_id) {
      Setting.current(service_id).then(function(data) {
        $scope.settings = data;
        if(!$scope.settings.configuration.opit.algorithm || $scope.settings.configuration.opit.algorithm == 1) {
          $scope.settings.configuration.opit.algorithm_days = "";
          $scope.displayAlgorithmDays = false;
          $scope.cc_enabled = true;
        } else {
          if($scope.settings.configuration.opit.algorithm == 2) {
            $scope.displayAlgorithmDays = true;
            $scope.cc_enabled = false;
          }
        }
        
        angular.element('select').select2({ width: '100%' });
        
      }, function(data) {
        console.error(data);
      });
    };

    $scope.selectAlgorithmDays = function () {
      if($scope.settings.configuration.opit.algorithm == 2) {
        $scope.settings.configuration.opit.algorithm_days = 2;
        $scope.displayAlgorithmDays = true;
        $("#algorithm_days").focus();
        $scope.cc_enabled = false;
      } else {
        $scope.displayAlgorithmDays = false;
        $scope.settings.configuration.opit.algorithm_days = "";
        $scope.cc_enabled = true;
      }
    };

    $scope.update = function() {
      Setting.update($scope.settings).then(function(data) {
        $scope.alerts.push({msg: 'Se han guardado los cambios.', type: 'success'});
      }, function(data) {
        console.error(data);
        $scope.alerts.push({msg: 'Hubo un problema al intentar guardar los cambios.', type: 'danger'});
      });
    };

    $scope.loadFullitConfiguration = function() {
      Setting.fullit().then(function(data) {
        $scope.fullit = data;
        $scope.sellers = _.map(data.configuration.fullit.sellers, function(seller) {
          Object.values(seller)[0].name = Object.keys(seller)[0];
          Object.values(seller)[0].setting = $scope.fullit.id;
          return Object.values(seller)[0];
        });
      }, function(error) {
        console.log(error);
      });
    };

    $scope.inactiveSellers = function (seller) {
      return ['dafiti', 'drupal', 'api2cart', 'opencart', 'bsale', 'magento_one', 'magento_two'].includes(seller.name);
    };

    $scope.editIntegration = function(seller) {

      if(seller.name == 'jumpseller') {
        window.open('https://jumpseller.cl/support/shipit/','_blank');
      } else if (seller.name != 'opencart') {
        Setting.launchModal(seller);
      };
    };

    $scope.closeAlert = function(index) {
      //window.location.href = '/settings';
      $scope.alerts = [];
    };

    $scope.loadModalSkus = function() {
      Sku.by_client().then(function(data) {
        Setting.skusModal(data.client_skus);
      }, function(error) {
        $scope.alerts.push({msg: 'Ha ocurrido un error, favor notificar a ayuda@shipit.cl indicando lo sucedido.', type: 'danger'});
      });
    };

    $scope.getIcon = function (courier) {
      return courier[Object.keys(courier)[0]].icon;
    };

    $scope.getName = function (courier) {
      return courier[Object.keys(courier)[0]].name;
    };

    $scope.getAcronym = function (courier) {
      return courier[Object.keys(courier)[0]].acronym;
    };

    $scope.modalTcc = function (setting, courier) {
      var modal = $uibModal.open({
        animation: true,
        ariaLabelledBy: 'modal-title',
        ariaDescribedBy: 'modal-body',
        templateUrl: 'modal_edit_tcc.html',
        controller: 'ModalEditTccController',
        size: 'lg',
        resolve: {
          setting: function () {
            return setting;
          },
          courier: function () {
            return courier;
          }
        }
      });
      modal.result.then(function (response) { }, function (error) { });
    };

  }])
  .controller('IntegrationEditModalInstanceController', ['$scope', '$uibModalInstance', 'seller', 'Setting', function($scope, $uibModalInstance, seller, Setting){
    $scope.alerts = [];
    $scope.seller = seller;
    $scope.availablePackings = ['Sin empaque','Caja de cartón', 'Film Plástico', 'Bolsa Courier + Burbuja', 'Bolsa Courier'];

    $scope.loadInfo = function() {

      $scope.helpUrl = undefined;
      switch($scope.seller.name) {
        case "bootic":
          $scope.helpUrl = "https://shipitcl.zendesk.com/hc/es-419/sections/360002687793-Bootic";
          break;
        case "jumpseller":
          $scope.helpUrl = "https://shipitcl.zendesk.com/hc/es-419/sections/360002770813-Jumpseller";
          break;
        case "shopify":
          $scope.helpUrl = "https://shipitcl.zendesk.com/hc/es-419/sections/360002687953-Shopify";
          break;
        case "woocommerce":
          $scope.helpUrl = "https://shipitcl.zendesk.com/hc/es-419/sections/360002687833-WooCommerce";
          break;
        case "prestashop":
          $scope.helpUrl = "https://shipitcl.zendesk.com/hc/es-419/sections/360002687813-Prestashop";
          break;
        case "vtex":
          $scope.helpUrl = "https://shipitcl.zendesk.com/hc/es-419/sections/360002687813-vtex";
          break;
      }

      $scope.configTitle = 'Configuración ' + $scope.seller.name;
      $scope.seller.clientId = $scope.seller.client_id;
      $scope.seller.clientSecret = $scope.seller.client_secret;
      $scope.seller.showShipitCheckout = $scope.seller.show_shipit_checkout;
      $scope.seller.automaticDelivery = $scope.seller.automatic_delivery;
      $scope.seller.storeName = $scope.seller.store_name;
      $scope.hour = $scope.seller.automatic_hour;
      $scope.package = $scope.seller.automatic_packing;
      $scope.automatic = $scope.seller.automatic;
    };

    $scope.integrateSeller = function() {
      if ($scope.automatic == true) {
        if($scope.hour != '' && $scope.hour != undefined) {
          sendIntegrate();
        } else {
          $scope.alerts.push({msg: 'Debes agregar hora para poder configurar el envío automatico.', type: 'danger'});
        }
      } else {
        sendIntegrate();
      }
    };

    var sendIntegrate = function() {
      var params = {
        service: 2,
        setting: $scope.seller.setting,
        data: {
          client_id: $scope.seller.clientId,
          client_secret: $scope.seller.clientSecret,
          automatic: $scope.automatic,
          hour: $scope.hour,
          packing: $scope.package,
          store_name: $scope.seller.storeName,
          store_keys: [],
          seller: $scope.seller.name,
          show_shipit_checkout: $scope.seller.showShipitCheckout,
          automatic_delivery: $scope.seller.automaticDelivery } };

      Setting.setFullit(params).then(function(data) {
        $scope.alerts.push({msg: 'Integración realizada con éxito', type: 'success'});
      }, function(error) {
        $scope.alerts.push({msg: 'Error en el proceso, favor contactar al área de desarrollo de Shipit.', type: 'danger'});
      });
    };

    $scope.closeAlert = function(index) {
      window.location.href = '/integrations';
    };

    $scope.validateSeller = function(seller) {
      return !['vtex'].includes(seller.name);
    };

  }]);
}).call(this);
