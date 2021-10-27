'use strict';

/**
* @name:Package
* @description: maintains Package data
* @attributes:
*
* | Name                  | Type           |
* |-----------------------|----------------|
* | @id                   | integer        |
* | @created_at           | datetime       |
* | @updated_at           | datetime       |
*
**/

(function() {
  this.app.factory('Package', ['$http', '$q', '$uibModal', function ($http, $q, $uibModal) {
    return {
      new: function(data) {
        return {
          full_name: '',
          email: '',
          reference: '',
          destiny: 'Domicilio',
          approx_size: '',
          packing: 'Sin Empaque',
          items_count: 1,
          shipping_type: 'Normal',
          is_payable: false,
          cellphone: '',
          without_courier: false,
          courier_for_client: '',
          is_sandbox: false,
          platform: data.platform || 0,
          address_attributes: {
            street: '',
            number: '',
            commune_id: '',
            complement: '',
            full: ''
          },
          courier_branch_office_id: 0,
          with_purchase_insurance: false,
          insurance_attributes: {
            detail: '',
            ticket_amount: '',
            ticket_number: '',
            extra: false
          }
        };
      },

      newReturn: function(model) {
        model.cellphone = parseInt(model.cellphone);
        model.is_returned = true;
        model.courier_for_client = '';
        model.courier_for_entity = '';
        model.courier_selected = false;
        model.status = 'in_preparation';
        model.tracking_number = '';
        model.courier_status = '';
        model.shipping_price = 0;
        model.total_price = 0;
        model.shipping_cost = 0;
        model.created_at = null;
        model.updated_at = null;
        model.courier_url = null;
        model.url_pack = null;
        model.pack_pdf = null;
        model.delayed = false;
        model.return_created_at = '';
        model.automatic_retry_date = '';
        model.trello_item = '';
        model.is_sized = false;
        model.inventory_activity = null;
        model.is_paid_shipit = false;
        model.platform = 6;
        model.address_attributes = model.address;
        return model;
      },

      index: function() {
        var defer = $q.defer();
        $http({
          url: 'today_packages',
          method: 'GET',
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      find: function(id) {
        var defer = $q.defer();
        $http({
          url: '/packages/find',
          method: 'GET',
          params: {
            id: id
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      create: function(data, headquarter) {
        var defer = $q.defer();
        $http({
          url: '/' + headquarter + 'packages',
          method: 'POST',
          data: {
            package: data
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      sendMassive: function(data, headquarter) {
        var defer = $q.defer();
        $http({
          url: '/packages/massive_packages',
          method: 'POST',
          data: {
            packages: data
          },
          timeout: 240000, // miliseconds 4 minutes
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      byBranchOfffice: function(branchOffice) {
        var defer = $q.defer();
        $http({
          url: '/headquarter/packages/by_branch_office',
          method: 'GET',
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      valid: function(data) {
        var error = this.new({ platform: data.platform || 0 });
        var valid = true;
        if (data.full_name == '') {
          error.full_name = true;
          valid = false;
        } else if (data.reference == '') {
          error.reference = true;
          valid = false;
        } else if (data.destiny == '') {
          error.destiny = true;
          valid = false;
        } else if (data.items_count == '') {
          error.items_count = true;
          valid = false;
        } else if (data.address_attributes.street == '') {
          error.address_attributes.street = true;
          valid = false;
        } else if (data.address_attributes.number == '') {
          error.address_attributes.number = true;
          valid = false;
        } else if (data.address_attributes.commune_id == '' || data.address_attributes.commune_id == 0) {
          error.address_attributes.commune_id = true;
          valid = false;
        }

        return { valid: valid, error: error };
      },

      courierIcon: function(courier) {
        var size;
        var response = '';
        if (courier !== null && courier !== '' && courier !== undefined) {
          switch (courier) {
            case 'chilexpress':
              size = 100;
              break;
            case 'starken':
              size = 70;
              break;
            default:
              courier = 'without';
            break;
          }
        } else {
          response = 'Sin Courier';
          courier = 'without';
        }
        response = response == '' ? 'ok' : response;
        return { response: response, link: '/assets/' + courier + '.png', size: size  };
      },

      courierTrackingLink: function(model) {
        var url = '';
        if (model.tracking_number == '' || model.tracking_number == null) {
          return { url: url, number: 'Sin número de seguimiento', klass: 'text-danger' };
        } else {
          if (model.courier_for_client == 'chilexpress') {
            url = 'http://chilexpress.cl/Views/ChilexpressCL/Resultado-busqueda.aspx?DATA=' + model.tracking_number;
          } else if (model.courier_for_client == 'starken') {
            url = 'https://www.starken.cl/seguimiento?codigo=' + model.tracking_number;
          }
        }
        return { url: url, number: model.tracking_number, klass: 'text-info' };
      },

      currentStatusFor: function(model) {
        var object = { message: '', klass: '' };
        var message, klass;
        switch (model.status) {
          case 'created':
            message = 'Creado', klass=  'created';
            break;
          case 'in_preparation':
            message = 'Preparando', klass=  'process';
            break;
          case 'in_route':
            message = 'En Ruta', klass=  'route';
            break;
          case 'delivered':
            message ='Entregado', klass = 'delivery';
            break;
          case 'failed':
            message = 'Rechazado', klass = 'fail';
            break;
          case 'by_retired':
            message = 'Por Retirar', klass = 'by-retired';
            break;
          case 'other':
            message = 'Otro', klass = 'other';
            break;
          case 'fulfillment':
            message = 'Creado', klass=  'created';
            break;
          default:
            message = 'Sin Estado Asignado', klass = 'fail';
            break;
        }
        object.message = message;
        object.klass = klass;
        return object;
      },

      fieldsTranslate: function() {
        return {
          full_name: 'Nombre Destinatario',
          email: 'Correo Electrónico',
          reference: 'ID / Referencia',
          destiny: 'Domicilio / Sucursal',
          approx_size: 'Tamaño Aproximado',
          packing: 'Empaque',
          items_count: 'Cantidad de Productos',
          shipping_type: 'Tipo de Envío',
          is_payable: 'Por pagar',
          courier_for_client: 'Courier',
          cellphone: 'Teléfono',
          address_attributes: {
            street: 'Calle',
            number: 'Número',
            commune_id: 'Comuna',
            complement: 'Complemento'
          }
        };
      },

      printLabels: function() {
        var defer = $q.defer();
        $http({
          url: '/v/labels',
          method: 'POST',
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(angular.extend(model.data, { status: model.status }));
        });
        return defer.promise;
      },

      update: function (edited) {
        var defer = $q.defer();
        $http({
          url: '/packages/'+edited.id,
          method: 'PATCH',
          data: {
            package: edited
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      returns: function (processed, search) {
        var defer = $q.defer();
        $http({
          url: '/returns/packages/operation',
          method: 'GET',
          params: {
            processed: processed,
            page: search.page,
            per: search.per
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      createReturn: function(returned) {
        var defer = $q.defer();
        $http({
          url: '/returns/packages',
          method: 'POST',
          data: {
            package: returned
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      returnToClient: function(packages) {
        var ids = [];
        if (Array.isArray(packages)){
          ids = _.pluck(packages, 'id');
        }
        else {
          ids = _.pluck([packages], 'id');
        }
        var defer = $q.defer();
        $http({
          url: '/returns/packages/to_client',
          method: 'POST',
          data: {
            ids: ids
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      whereReferences: function(references) {
        var defer = $q.defer();
        $http({
          url: '/packages/by_references',
          method: 'POST',
          data: {
            references: references
          }
        }).then(function (model) {
          defer.resolve(model.data);
        }, function (model) {
          defer.reject(model.data);
        });
        return defer.promise;
      }

    };
  }]);
}).call(this);
