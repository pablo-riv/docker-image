(function() {
  this.app.service('PackageService', ['$q', '$uibModal', function($q, $uibModal) {
    return {
      lauchModal: function(checkoutPackage, hasFulfillment, skus, controller) {
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'packageCheckoutModal.html',
          controller: controller,
          size: 'lg',
          resolve: {
            checkoutPackage: function() {
              return checkoutPackage;
            },
            hasFulfillment: function() {
              return hasFulfillment;
            },
            skus: function() {
              return skus;
            }
          }
        });
        modal.result.then(function() {
        }, function(error) {
        });
      },

      lauchMassiveSkusModal: function(skus) {
        var defer = $q.defer();
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'massiveSkusModal.html',
          controller: 'MassiveSkusModalInstanceController',
          size: 'lg',
          resolve: {
            skus: function() {
              return skus;
            }
          }
        });
        modal.result.then(function(data) {
          defer.resolve(data);
        }, function(error) {
          defer.reject(error);
        });
        return defer.promise;
      },

      launchLoadMassivePackagesModal: function(skus, communes, hasFulfillment) {
        var defer = $q.defer();
        var modal = $uibModal.open({
          animation: true,
          ariaLabelledBy: 'modal-title',
          ariaDescribedBy: 'modal-body',
          templateUrl: 'LoadMassivePackagesModal.html',
          controller: 'LoadMassivePackagesModalInstanceController',
          size: 'xl',
          resolve: {
            skus: function() {
              return skus;
            },
            communes: function() {
              return communes;
            },
            hasFulfillment: function() {
              return hasFulfillment;
            }
          }
        });
        modal.result.then(function(data) {
          defer.resolve(data);
        }, function(error) {
          defer.reject(error);
        });
        return defer.promise;
      },

      validate: function(model, hasFulfillment, skus) {
        var defer = $q.defer();
        var basicData = this.basicData(model);
        var courierType = this.courierType(model);

        if (!basicData.valid) {
          defer.reject({message: basicData.message, hasFulfillment: hasFulfillment});
        } else if (!courierType.valid) {
          defer.reject({message: courierType.message, hasFulfillment: hasFulfillment});
        } else if (hasFulfillment) {
          var check = this.inventoryActivity(skus);
          if (!check.valid) {
            defer.reject({message: check.message, hasFulfillment: hasFulfillment, withoutSkus: true});
          } else {
            defer.resolve();
          }
        } else {
          defer.resolve();
        }
        return defer.promise;
      },

      basicData: function(model) {
        var ready = { valid: false, message: '' }
        if (model.full_name == '') {
          ready.message = 'Debes ingresar nombre del destinatario';
        } else if (model.reference == '' || model.reference.length > 15) {
          ready.message = 'Debes ingresar referencia y no puede ser mayor a 12 caracteres';
        } else if (model.destiny == '') {
          ready.message = 'Debes seleccionar destino';
        } else if (model.items_count == '') {
          ready.message = 'Debes ingresar la cantidad de productos';
        } else if (model.address_attributes.street == '') {
          ready.message = 'Debes ingresar calle';
        } else if (model.address_attributes.number == '') {
          ready.message = 'Debes ingresar número';
        } else if (model.address_attributes.commune_id == '') {
          ready.message = 'Debes seleccionar comuna';
        } else {
          ready.valid = true;
        }
        return ready;
      },

      inventoryActivity: function(skus) {
        var ready = { valid: false, message: '' };
        if (skus == undefined || skus.length < 1) {
          ready.message = "Debes añadir SKU'S";
        } else {
          ready.valid = true;
        }
        return ready;
      },

      courierType: function(model) {
        var ready = { valid: false, message: '' };
        if (model.destiny == 'Domicilio' && model.courier_for_client == 'Chilexpress' && model.is_payable == true) {
          ready.message = 'No puedes realizar envíos por pagar a domicilio y con courier Chilexpress';
        } else if (model.destiny == 'Chilexpress' && model.courier_for_client == 'Starken-Turbus') {
          ready.message = 'No puedes realizar envíos por Starken y enviar a Sucursal Chilexpress';
        } else if (model.destiny == 'Starken-Turbus' && model.courier_for_client == 'Chilexpress') {
          ready.message = 'No puedes realizar envíos por Chilexpress y enviar a Sucursal Starken';
        } else {
          ready.valid = true;
        }
        return ready;
      },

      purchaseAvailables: function() {
        return ['Accesorios de Moda', 'Accesorios y repuestos para autos/motos.', 'Artículos de Deporte',
                'Bolsas, Maletas y Accesorios de Viaje', 'Cámaras, Videocámaras y/o Accesorios',
                'CD, casetes, vinilos y otras grabaciones de sonido', 'Celulares y/o Accesorios',
                'Computadoras personales y/o Accesorios', 'Enganches, suministros científicos y/o de laboratorio',
                'Herramientas y Mejoras del hogar', 'Instrumentos Musicales', 'Insumos de Oficina y Papelería',
                'Juguetes y Juegos', 'Libros y/o Revistas', 'Productos de Bebé', 'Productos de Belleza y Salud',
                'Productos de Hogar y Cocina', 'Productos de Mascotas', 'Relojes', 'Ropa',
                'Software empresarial, de educación, de utilidades, de seguridad y para niños',
                'Televisores, equipos de música y GPS', 'Video, DVD y Blu-ray', 'VIdeojuegos', 'Zapatos', 'Otros productos de venta online'];
      },

      markCourierSelected: function(data) {
        for (var i = 0; i < data.length; i++) {
          if (data[i].package_courier_for_client != undefined && data[i].package_courier_for_client != '') {
            data[i].package_courier_selected = true;
          }
        }
        return data;
      }

    };
  }]);
}).call(this);
