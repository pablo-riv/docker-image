(function() {
  this.app.controller('EditOrderFormatConfigModalInstanceController', ['$scope', '$uibModalInstance', 'seller', 'orders', 'Setting', 'Order', function($scope, $uibModalInstance, seller, orders, Setting, Order) {
    $scope.alerts = [];
    $scope.seller = seller;
    $scope.orders = orders;
    $scope.orderIndex = 0;
    $scope.order = Order.minimizeApi2CartFields($scope.orders[$scope.orderIndex]);
    $scope.properties = { commune: [], street: [], number: [], complement: [] };

    var extract = function(chain) {
      var value = angular.merge({}, $scope.order);
      angular.forEach(chain.split('&'), function(field) {
        var partialValue = value[field];
        value = $scope.kindOf(partialValue) == 'array' ? partialValue[0] : partialValue;
      });
      return value;
    };

    var notWords = function(str) {
      return _.compact(str.replace(/[^0-9\s]/g, '').trim().split(' '));
    };

    var notNumbers = function(str) {
      return _.compact(str.replace(/[0-9\s]/g, '').trim().split(' '));
    };

    var partialCommune = function() {
      return _.map($scope.properties.commune, function(communeFields) { return extract(communeFields); })[0];
    };

    var partialNumber = function(str) {
      return notWords(str)[0];
    };

    var partialStreet = function(str) {
      return str.split(notWords(str)[0])[0];
    };

    var partialComplement = function(str) {
      return str.split(notWords(str)[0])[1];
    };

    var partialOf = function(properties, type) {
      var str = _.reduce(_.map(properties, function(prop) { return extract(prop); }), function(memo, val) { return memo + (' ' + val); }, '');
      switch (type) {
        case 'street':
          str = partialStreet(str);
          break;
        case 'number':
          str = partialNumber(str);
          break;
        case 'complement':
          str = partialComplement(str);
          break;
      }
      return str;
    };

    var calculatePartials = function() {
      $scope.streetPartial = partialOf($scope.properties.street, 'street');
      $scope.numberPartial = partialOf($scope.properties.number, 'number');
      $scope.complementPartial = partialOf($scope.properties.complement, 'complement');
      $scope.communePartial = partialCommune();
    };

    var addFieldValue = function(field, value) {
      $scope.properties[field].push(value);
      calculatePartials();
      $scope.$apply();
    };

    var existValue = function(field, value) {
      var exist = false;
      angular.forEach($scope.properties[field], function(fieldValue) {
        if (fieldValue == value) {
          exist = true;
        }
      })
      return exist;
    };

    var dragAndDropFields = function() {
      angular.element('.draggable').draggable({
        revert: true
      });
      angular.element('.droppable').droppable({
        drop: function(event, ui) {
          var field = angular.element(this).data('field');
          var value = angular.element(ui.draggable[0]).data('prop');
          if (!existValue(field, value)) {
            addFieldValue(field, value);
          }
        }
      });
    };

    $scope.removeFieldValue = function(field, value) {
      var index = $scope.properties[field].indexOf(value);
      $scope.properties[field].splice(index, 1);
      calculatePartials();
    };

    $scope.loadFields = function() {
      Setting.fullit().then(function(data) {
        $scope.fullit = data;
        angular.forEach(data.configuration.fullit.sellers, function(seller) {
          var name = Object.keys(seller)[0];
          var config = Object.values(seller)[0];
          if (name == $scope.seller) {
            $scope.config = config;
            if (config.fields != undefined && config.fields != null) {
              $scope.properties = config.fields;
            }
          }
        });
        dragAndDropFields();
        calculatePartials();
      }, function(error) {
        $scope.alerts.push({ msg: 'Tuvimos problemas para cargar su configuración, intentelo denuevo más tarde.', type: 'danger' });
        console.error(error);
      });
    };

    $scope.saveFieldsStructure = function() {
      $scope.config.fields = $scope.properties;
      $scope.config.seller = $scope.seller;
      var params = {
        service: $scope.fullit.service_id,
        setting: $scope.fullit.id,
        data: $scope.config
      };
      Setting.setFullit(params).then(function(data) {
        $scope.alerts.push({ msg: 'Cambios guardados correctamente.', type: 'success' });
        setTimeout(function() { window.location.reload(); }, 3000);
      }, function(error) {
        $scope.alerts.push({ msg: 'Hubo un error intentado guardar su configuración, intentelo denuevo más tarde.', type: 'danger' });
        console.error(error);
      });
    };

    $scope.changeOrder = function(number) {
      var maxLength = $scope.orders.length;
      if (number == 1) {
        if ($scope.orderIndex < maxLength - 1) {
          $scope.orderIndex += number;
          $scope.order = Order.minimizeApi2CartFields($scope.orders[$scope.orderIndex]);
        }
      } else {
        if ($scope.orderIndex != 0) {
          $scope.orderIndex += number;
          $scope.order = Order.minimizeApi2CartFields($scope.orders[$scope.orderIndex]);
        }
      }
      calculatePartials();
    }

    $scope.fields = function(obj) {
      return Object.keys(obj);
    };

    $scope.values = function(obj) {
      return Object.values(obj);
    };

    $scope.kindOf = function(val) {
      return Array.isArray(val) ? 'array' : typeof val;
    };

    $scope.closeAlert = function(index) {};

    $scope.close = function() {
      $uibModalInstance.close();
    };
  }])
}).call(this);