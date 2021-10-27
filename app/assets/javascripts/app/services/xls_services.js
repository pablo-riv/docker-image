(function() {
  this.app.service('XlsService', ['$filter', '$q', 'Sku', 'Package', 'InsuranceService', 'Order', function ($filter, $q, Sku, Package, InsuranceService, Order) {
    var normalizeExpression = function(str) {
      return str.replace(/[\W]/g, '');
    };

    var checkPayable = function (data, hasFulfillment) {
      try {
        if (['chilexpress', 'dhl'].includes(data.courier_for_client.toLowerCase()) && data.is_payable && data.destiny == 'Domicilio') {
          alert('No se puede generar envíos Chilexpress o DHL, con destino a domicilo y con valor por pagar\nSe ha cambiado automaticamente el courier a Starken ID envio' + data.reference);
          data.courier_for_client = 'starken';
        } else if (['dhl'].includes(data.courier_for_client.toLowerCase()) && data.is_payable) {
          alert('No se puede generar envíos DHL con valor por pagar\nSe ha cambiado automaticamente el courier a Starken ID envio' + data.reference);
          data.courier_for_client = 'starken';
        } else if (['muvsmart'].includes(data.courier_for_client.toLowerCase()) && data.is_payable) {
          alert('No se puede generar envíos MuvSmart con valor por pagar\nSe ha cambiado automaticamente el courier a Starken ID envio' + data.reference);
          data.courier_for_client = 'starken';
        } else if (['shippify'].includes(data.courier_for_client.toLowerCase()) && data.is_payable) {
          alert('No se puede generar envíos Shippify con valor por pagar\nSe ha cambiado automaticamente el courier a Starken ID envio' + data.reference);
          data.courier_for_client = 'starken';
        } else if (hasFulfillment != null && data.is_payable && data.courier_for_client.toLowerCase() != 'starken') {
          alert('No se puede generar envíos con valor por pagar\nSe ha cambiado automaticamente el courier a Starken ID envio' + data.reference);
          data.courier_for_client = 'starken';
        }
      } catch (error) {

      } finally {
        return data;
      }
    };

    var validateNecessarydata = function(orders) {
      orders = orders.map(function (order, index) {
        try {
          order.customer_name_error = ['', null, undefined].includes(order.customer_name) ? true : false;
          order.seller_reference_error = ['', null, undefined].includes(order.seller_reference) ? true : false;
          order.shipping_data_street_error = ['', null, undefined].includes(order.shipping_data.street) ? true : false;
          order.shipping_data_number_error = ['', null, undefined].includes(order.shipping_data.number) ? true : false;
          order.commune_name_error = ['', null, undefined].includes(order.commune.name) ? true : false;
          order.package_destiny_error = ['', null, undefined].includes(order.package_destiny) ? true : false;

          order.packing = 'Sin empaque'; 
        } catch (error) {
          order.undetected_error = true;
        }
        return order;
      });
      return _.compact(orders);
    };

    var checkInsurance = function (data) {
      if (data.address_attributes.commune == '') return data;
      if (data.with_purchase_insurance) {
        data.insurance = InsuranceService.new(data);
      } else {
        data.insurance = { maxSecure: 0, amount: 0, price: 0 }
      }
      return data;
    };

    var FFTemplate = function (keys, value, branchOffice, communes, index) {
      var foundCommune = _.find(communes, function (commune) {
        return commune.name == value[keys[4]]
      });
      if (foundCommune == undefined) alert('No se encontró la comuna: ' + value.v + ' especificada en la fila' + (index + 1));
      var commune = foundCommune == undefined ? '' : foundCommune.name.toUpperCase();
      var commune_id = foundCommune == undefined ? '' : foundCommune.id;
      return {
        branch_office_id: parseInt(branchOffice),
        full_name: value[keys[6]],
        email: value[keys[10]],
        reference: value[keys[0]],
        destiny: value[keys[5]],
        packing: 'Sin Empaque',
        items_count: value[keys[2]],
        shipping_type: value[keys[3]],
        is_payable: value[keys[12]] == undefined ? false : $filter('parseBoolean')(value[keys[12]]),
        cellphone: value[keys[11]],
        courier_for_client: value[keys[14]],
        address_attributes: {
          street: value[keys[7]],
          number: value[keys[8]],
          commune_id: commune_id,
          complement: value[keys[9]],
          commune: commune
        },
        skus: value[keys[1]],
        amount: value[keys[2]]
      };
    };

    var PPTemplate = function (keys, value, branchOffice, communes, index) {
      var foundCommune = _.find(communes, function (commune) {
        return commune.name == value[keys[4]]
      });
      if (foundCommune == undefined) alert('No se encontró la comuna: ' + value.v + ' especificada en ' + (index + 1));
      var commune = foundCommune == undefined ? '' : foundCommune.name.toUpperCase();
      var commune_id = foundCommune == undefined ? '' : foundCommune.id;
      return {
        branch_office_id: parseInt(branchOffice),
        full_name: value[keys[6]],
        email: value[keys[11]],
        reference: value[keys[0]],
        destiny: value[keys[5]],
        approx_size: value[keys[10]],
        packing: 'Sin Empaque',
        items_count: value[keys[2]],
        shipping_type: value[keys[3]],
        is_payable: value[keys[13]] == undefined ? false : $filter('parseBoolean')(value[keys[13]]),
        cellphone: value[keys[12]],
        courier_for_client: value[keys[15]],
        address_attributes: {
          street: value[keys[7]],
          number: value[keys[8]],
          commune_id: commune_id,
          complement: value[keys[9]],
          commune: commune
        }
      };
    };

    return {
      process: function(workbook, skus, data, company) {
        var sheet = workbook.SheetNames[0];
        var worksheet = workbook.Sheets[sheet];
        var lastColumn = Object.values(worksheet)[0].split(':')[1].substring(0, 1);
        angular.forEach(worksheet, function(value, index) {
          if (index == '!ref' || index == 'A1' || index == 'B1' || index == 'C1' || index == 'D1') {
            console.warn(value.v);
          } else {
            data.sku.company_id = parseInt(company.id);
            var column = index.substring(0, 1);
            switch (column) {
              case 'A':
                data.sku.name = value.v;
                break;
              case 'B':
                data.sku.amount = parseInt(value.v);
                break;
              case 'C':
                data.sku.min_amount = parseInt(value.v);
                break;
              case 'D':
                data.sku.description = value.v;
                break;
              default:
                break;
            };
            if (column == lastColumn) {
              skus.push(data);
              data = Sku.new();
            }
          }
        });
        return skus;
      },

      processPackageMassive: function (workbook, packages, data, communes, branchOffice, hasFulfillment) {
        var sheet = workbook.SheetNames[0];
        var worksheet = workbook.Sheets[sheet];
        var keys = [];
        angular.forEach(worksheet, function (value, index) {
          var row = index.substring(1, index.length);
          if (row == '1') keys.push(value.v);
        });
        var packages = _.map(XLSX.utils.sheet_to_json(worksheet, { raw: false }), function (value, index) {
          if (hasFulfillment == null) {
            data = PPTemplate(keys, value, branchOffice, communes, index);
          } else {
            data = FFTemplate(keys, value, branchOffice, communes, index);
          }

          data = checkPayable(data, hasFulfillment);
          data = checkInsurance(data);
          return data;
        });

        return packages;
      },
      processMassiveOrderPrint: function (workbook) {
        var defer = $q.defer();
        var sheet = workbook.SheetNames[0];
        var worksheet = workbook.Sheets[sheet];
        var keys = [];
        angular.forEach(worksheet, function (value, index) {
          var row = index.substring(1, index.length);
          if (row == '1') keys.push(value.v);
        });
        var references = _.map(XLSX.utils.sheet_to_json(worksheet, { raw: false }), function (value, index) {
          return value[Object.keys(value)[0]];
        });

        if (_.uniq(references).length < references.length) {
          alert('Se han encontrado ' + (references.length - _.uniq(references).length) + ' envío(s) con ID repetidos en el archivo, sólo se imprimirá la primera vez que aparece en el listado y los demás serán omitidos.');
        }

        Package.whereReferences(references).then(function(data) {
          if (references.length !== data.packages.length) {
            alert('Se han encontrado ' + (references.length - data.packages.length) + ' envíos con ID no existentes, éstos serán omitidos para la impresión.');
          }
          defer.resolve(data.packages);
        }, function(error) {
          defer.reject(error);
        });
        return defer.promise;
      },

      processMassiveOrderToCreate: function (workbook) {
        var defer = $q.defer();
        var sheet = workbook.SheetNames[0];
        var worksheet = workbook.Sheets[sheet];
        var keys = [];
        angular.forEach(worksheet, function (value, index) {
          var row = index.substring(1, index.length);
          if (row == '1') keys.push(value.v);
        });
        var orders = _.map(XLSX.utils.sheet_to_json(worksheet, { raw: false }), function (value, index) {
          return { seller_reference: value[Object.keys(value)[0]], seller: value[Object.keys(value)[1]].toLowerCase() };
        });

        if (_.uniq(orders).length < orders.length) {
          alert('Se han encontrado ' + (orders.length - _.uniq(orders).length) + ' orden(es) con ID repetidos en el archivo, sólo se desplegara la primera vez que aparece en el listado y los demás serán omitidos.');
        }
        Order.whereReferencesAndSeller(orders).then(function(data) {
          if (orders.length !== data.orders.length) {
            alert('Se han encontrado ' + (orders.length - data.orders.length) + ' ordenes con ID no existentes, éstos serán omitidos.');
          }

          
          defer.resolve(validateNecessarydata(data.orders));
        }, function(error) {
          defer.reject(error);
        });
        return defer.promise;
      }
    };
  }]);
}).call(this);
