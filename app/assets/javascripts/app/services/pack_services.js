(function() {
  this.app.service('PackService', ['$uibModal', '$q', 'Pack', function($uibModal, $q, Pack) {
    return {
      findPackage: function(model, $event) {
        var defer = $q.defer();
        var self = this;
        if ($event.type == 'click' && model.id != '' || ($event.type == 'keyup' && $event.keyCode == 13)) {
          Pack.findById(model).then(function(data) {
            var alert = '';
            alert += self.validatePayable(data.package);
            defer.resolve({package: data.package, alert: alert});
          }, function(e) {
            console.error(e);
            defer.reject({message: 'Envío no encontrado.', state: 'error' });
          });

        } else {
          if ($event.type !== 'keyup') {
            defer.reject({message: 'Debes ingresar un ID de envío.', state: 'error'});
          } else {
            defer.reject({message: '', state: 'okish'});
          }
        }
        return defer.promise;
      },

      validatePayable: function (data) {
        try {
          if (data.courier_for_client.toLowerCase() != 'starken') {
            if (data.is_payable == true) {
              return 'Envío por pagar, entregar a encargado.\n';
            }
          }
          return '';
        } catch (e) {
          console.error(e);
          return 'Envío sin courier, entregar a encargado\n';
        }
      }

    };
  }]);
}).call(this);
