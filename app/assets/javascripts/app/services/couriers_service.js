(function () {
  this.app.service('CourierService', ['$q', function ($q) {
    return {
      couriers: function () {
        return [
          { name: 'Envío rápido más económico', value: '' },
          { name: 'Chilexpress', value: 'chilexpress', system: 'chilexpress', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/chilexpress.png', acronym: 'cxp' },
          { name: 'Starken', value: 'starken', system: 'starken', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/starken.png', acronym: 'stk' },
          { name: 'Correos Chile', value: 'correoschile', system: 'correoschile', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/correoschile.png', acronym: 'cc' },
          // { name: 'DHL', value: 'dhl', system: 'dhl', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/dhl.png', acronym: 'dhl' },
          { name: 'MuvSmart', value: 'muvsmart', system: 'muvsmart', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/muvsmart.png', acronym: 'muvsmart' },
          { name: 'Chile Parcels', value: 'chileparcels', system: 'chileparcels', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/chileparcels.png', acronym: 'chileparcels' },
          { name: 'Moto Partner', value: 'motopartner', system: 'motopartner', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/motopartner.png', acronym: 'motopartner' },
          { name: 'Bluexpress', value: 'bluexpress', system: 'bluexpress', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/bluexpress.png', acronym: 'bluexpress' },
          { name: 'Shippify', value: 'shippify', system: 'shippify', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/shippify.png', acronym: 'shippify' }
        ];
      },
      oldCouriers: function () {
        return [
          { name: 'Envío rápido más económico', value: '' },
          { name: 'Chilexpress', value: 'chilexpress', system: 'chilexpress', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/chilexpress.png', acronym: 'cxp' },
          { name: 'Starken', value: 'starken', system: 'starken', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/starken.png', acronym: 'stk' },
          // { name: 'DHL', value: 'dhl', system: 'dhl', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/dhl.png', acronym: 'dhl' },
          { name: 'MuvSmart', value: 'muvsmart', system: 'muvsmart', icon: 'https://s3.us-west-2.amazonaws.com/couriers-shipit/muvsmart.png', acronym: 'muvsmart' },
          { name: 'Chile Parcels', value: 'chileparcels', system: 'chileparcels', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/chileparcels.png', acronym: 'chileparcels' },
          { name: 'Moto Partner', value: 'motopartner', system: 'motopartner', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/motopartner.png', acronym: 'motopartner' },
          { name: 'Bluexpress', value: 'bluexpress', system: 'bluexpress', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/bluexpress.png', acronym: 'bluexpress' },
          { name: 'Shippify', value: 'shippify', system: 'shippify', icon: 'https://s3-us-west-2.amazonaws.com/couriers-shipit/shippify.png', acronym: 'shippify' }
        ];
      },
      rules: function (courier, destiny, isPayable, availablesDestinitiesStarken, communeName) {
        var defer = $q.defer();
        var response = { valid: true, message: '' };
        try {
          switch (courier) {
            case 'chilexpress':
              defer.resolve(this.chilexpress(destiny, isPayable, response));
              break;
            case 'starken':
              defer.resolve(this.starken(destiny, isPayable, response, availablesDestinitiesStarken, communeName));
              break;
            case 'correoschile':
            case 'correos chile':
              defer.resolve(this.correoschile(destiny, isPayable, response));
              break;
            case 'dhl':
              defer.resolve(this.dhl(destiny, isPayable, response));
              break;
            case 'muvsmart':
              defer.resolve(this.muvsmart(destiny, isPayable, response));
              break;
            case 'chileparcels':
              defer.resolve(this.chileparcels(destiny, isPayable, response));
              break;
            case 'motopartner':
              defer.resolve(this.motopartner(destiny, isPayable, response));
              break;
            case 'bluexpress':
              defer.resolve(this.bluexpress(destiny, isPayable, response));
              break;
            case 'shippify':
              defer.resolve(this.shippify(destiny, isPayable, response));
              break;
            case 'envío rápido más económico':
              defer.resolve(response);
              break;
            default:
              if (courier.indexOf("Envío más barato a ") == 0) {
                defer.resolve(response);
              } else {
                response.valid = false;
                response.message = '¡No se encontro courier para la órden por favor agregar!';
                defer.reject(response);
              }
              break;
          }
        } catch (e) {
          response.valid = false;
          defer.reject(false);
        }
        return defer.promise;
      },

      chilexpress: function (destiny, isPayable, response) {
        try {
          if (isPayable == true && destiny == 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: Chilexpress, destino: Domicilio y opcion por pagar no son permitidas.';
          } else if (!['chilexpress', 'domicilio', 'sucursal chilexpress'].includes(destiny.toLowerCase())) {
            response.valid = false;
            response.message = 'La combinación de courier: Chilexpress, destino: ' + destiny + ' no son permitidas.';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },

      starken: function (destiny, isPayable, response, availablesDestinities, communeName) {
        try {
          if (!['domicilio', 'starken-turbus', 'sucursal starken-turbus'].includes(destiny.toLowerCase())) {
            response.valid = false;
            response.message = 'La combinación de courier: Starken, destino: ' + destiny + ' no son permitidas.';
          }
          if (destiny == 'domicilio' && isPayable && (communeName != undefined && communeName != "")) {
            if (availablesDestinities.includes(communeName)) {
              response.valid = false;
              response.message = 'Destino no disponible para despacho por pagar con el courier Starken';
            }
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },

      correoschile: function (destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio' && destiny != 'correoschile') {
            response.message = 'La combinación de courier: Correos Chile, destino: ' + destiny + ' no son permitidas.';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },

      dhl: function (destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: DHL, destino: ' + destiny + ' no son permitidas.';
          } else if (isPayable == true && destiny == 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: DHL, destino: Domicilio y opcion por pagar no son permitidas.';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },
      muvsmart: function (destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: MuvSmart, destino: ' + destiny + ' no son permitidas.';
          } else if (isPayable == true) {
            response.valid = false;
            response.message = 'La opcion por pagar no es permitida.';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },
      chileparcels: function (destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: Chileparcels, destino: ' + destiny + ' no son permitidas.';
          } else if (isPayable == true) {
            response.valid = false;
            response.message = 'La opcion por pagar no es permitida';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },
      motopartner: function (destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: Motopartner, destino: ' + destiny + ' no son permitidas.';
          } else if (isPayable == true) {
            response.valid = false;
            response.message = 'La opcion por pagar no es permitida';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },
      bluexpress: function(destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: Bluexpress, destino: '+ destiny +' no son permitidas.';
          } else if (isPayable == true) {
            response.valid = false;
            response.message = 'La opcion por pagar no es permitida';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },
      shippify: function(destiny, isPayable, response) {
        try {
          if (destiny != 'domicilio') {
            response.valid = false;
            response.message = 'La combinación de courier: Shippify, destino: '+ destiny +' no son permitidas.';
          } else if (isPayable == true) {
            response.valid = false;
            response.message = 'La opcion por pagar no es permitida';
          }
        } catch (e) {
          response.valid = false;
          response.message = 'Ha ocurrido un error no detectado, favor comunicarte con soporte@shipit.cl';
        };
        return response;
      },

      availablesDestinities: function (courier, cbosByCouriers) {
        var destinations = []
        var old_destinations = [];
        cbos = [];
        if (courier == undefined || courier == '') {
          return { destinations: [], old_destinations: [], cbos: [] };
        }
        switch (courier.toLowerCase()) {
          case 'chilexpress':
            destinations = ['Domicilio', 'Chilexpress'];
            old_destinations = ['Domicilio', 'Chilexpress'];
            cbos = cbosByCouriers.cxp;
            break;
          case 'starken':
            destinations = ['Domicilio', 'Starken-Turbus'];
            old_destinations = ['Domicilio', 'Starken-Turbus'];
            cbos = cbosByCouriers.stk;
            break;
          case 'correoschile', 'correos chile':
            destinations = ['Domicilio', 'CorreosChile'];
            old_destinations = ['Domicilio', 'CorreosChile'];
            cbos = [];
            break;
          case 'dhl':
            destinations = ['Domicilio'];
            old_destinations = ['Domicilio'];
            cbos = []
            break;
          case 'shippify':
            destinations = ['Domicilio'];
            old_destinations = ['Domicilio'];
            cbos = []
            break;
          default:
            destinations = ['Domicilio'];
            old_destinations = ['Domicilio'];
            cbos = [];
            break;
        }
        return { destinations: destinations, old_destinations: old_destinations, cbos: cbos };
      },

      icon: function (courier) {
        var icon;
        try {
         switch (courier.toLowerCase()) {
           case 'chilexpress':
             icon = 'chilexpress-icon chilexpress-color';
             break;
           case 'dhl':
             icon = 'dhl-icon dhl-color';
             break;
           case 'muvsmart':
             icon = 'muvsmart-icon muvsmart-color';
             break;
           case 'chileparcels':
             icon = 'chileparcels-icon chileparcels-color';
             break;
           case 'motopartner':
             icon = 'motopartner-icon motopartner-color';
             break;
           case 'starken':
             icon = 'starken-icon starken-color';
             break;
           case 'correos':
           case 'correoschile':
             icon = 'correos-icon correos-color';
             break;
           case 'bluexpress':
             icon = 'bluexpress-icon bluexpress-color';
             break;
           case 'shippify':
             icon = 'shippify-icon shippify-color';
             break;
           default:
             icon = 'shipit-icon shipit-color';
             break;
         }
        } catch (error) {
          icon = 'shipit-icon shipit-color';
        }
        return icon;
      },

      getIcon: function (courier) {
        data = this.couriers().find(function (data) {
          if (data.system == courier) {
            return data;
          }
        });
        return data.icon;
      }
    };
  }]);
}).call(this);
