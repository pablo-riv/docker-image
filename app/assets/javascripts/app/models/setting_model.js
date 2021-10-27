(function(){
  this.app.factory('Setting', ['$http','$q', '$uibModal', function($http, $q, $uibModal){
    var url = "/settings/";
    
    return {
      current: function(service_id){
        var defer = $q.defer();
        $http({
          url: url + "current",
          method: "GET",
          params: {
            service_id: service_id
          }
        }).then(function(model){
          defer.resolve(model.data);
        }, function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      },
      fullit: function(){
        var defer = $q.defer();
        $http({
          url: url + "fullit_setting",
          method: "GET"
        }).then(function(model){
          defer.resolve(model.data);
        }, function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      },
      sellersIntegrated: function() {
        var defer = $q.defer();
        $http({
          url: url + 'sellers_integrated',
          method: 'GET'
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      update: function(data){
        var defer = $q.defer();
        $http({
          url: "/services/" + data.service_id + url + data.id,
          method: "PUT",
          data: {
            setting: data
          }
        }).then(function(model){
          defer.resolve(model.data);
        },function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      },
      setFullit: function(info){
        var defer = $q.defer();
        $http({
          url: "/services/" + info.service + url + info.setting + '/update_integrations',
          method: "PATCH",
          data: {
            data: info.data
          }
        }).then(function(model){
          defer.resolve(model.data);
        },function(model){
          defer.reject(model.data);
        });
        return defer.promise;
      },
      launchModal: function(seller) {
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'integrationEdit.html',
          controller: 'IntegrationEditModalInstanceController',
          size: 'lg',
          resolve: {
            seller: function() {
              return seller;
            }
          }
        });
        modal.result.then(function() {
        }, function(error) {
        });
      },
      skusModal: function(skus) {
        var modal = $uibModal.open({
          animation: true,
          templateUrl: 'security_stock.html',
          controller: 'SecurityStockController',
          size: 'lg',
          resolve: {
            skus: function() {
              return skus;
            }
          }
        });
        modal.result.then(function() {
        }, function(error) {
        });
      },
      injectConfiguration: function (setting, format) {
        if (setting.configuration.printers.available_to_add_providers) {
          setting.configuration.printers.availables = [format];
        } else {
          for (var i = 0; i < setting.configuration.printers.availables.length; i++) {
            if (setting.configuration.printers.availables[i].active) {
              for (var j = 0; j < setting.configuration.printers.formats.length; j++) {
                if (setting.configuration.printers.availables[i].type === setting.configuration.printers.formats[j].format) {
                  setting.configuration.printers.availables[i].img = setting.configuration.printers.formats[j].img;
                  setting.configuration.printers.availables[i].display = setting.configuration.printers.formats[j].display;
                  setting.configuration.printers.availables[i].quantity = setting.configuration.printers.formats[j].quantity;
                  setting.configuration.printers.availables[i].type = setting.configuration.printers.formats[j].format;
                }
              }
            }
          }
        }
        return setting;
      },
      printer: function(configuration) {
        var availables = configuration.availables.filter(function (available) { return available.active });
        availables = availables[0];
        return angular.extend(availables, {
          kind_of_print: configuration.kind_of_print,
          label_package_size: configuration.label_package_size
        });
      }
    };
  }]);
}).call(this);
