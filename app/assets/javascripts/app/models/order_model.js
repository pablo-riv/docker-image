'use strict';

/**
 * @name: ORDER
 * @description: Maintains ORDER data
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
  this.app.factory('Order', ['$http', '$q', function($http, $q) {
    return {
      all: function(search) {
        var defer = $q.defer();
        $http({
          url: '/integrations/integration_orders',
          method: 'GET',
          params: {
            page: search.page,            
            filter: search.filter,
            seller_reference: search.seller_reference,
            from_date: search.from_date,
            to_date: search.to_date,
            per: search.per
          }
        }).then(function(model) {
          var newOnes = [];
          var archivedOnes = [];
          _.each(model.data.data.orders, function(value, index) {
            if (value.packing === undefined || value.packing === "") {
              value.packing = 'Sin Empaque';
            }
            if (value.package_destiny === undefined) {
              value.package_destiny = 'Domicilio';
            }
            if (value.package_payable === undefined) {
              value.package_payable = false;
            }
            if (value.selected === undefined) {
              value.selected = false;
            }
            if (value.package_destiny != 'Starken-Turbus') {
              value.package_cbo = null;
            }
            value.itemsKindOfArray = value.seller == 'dafiti' ? Array.isArray(value.items.order_item) : false;
            if (value.archive == true) {
              archivedOnes.push(value);
            } else {
              newOnes.push(value);
            }
          });
          defer.resolve({ totalOrdersCount: model.data.data.total_orders,
                          displayedOrdersCount: model.data.data.orders.length,
                          filter: model.data.data.filter,
                          newOnes: newOnes,
                          archivedOnes: archivedOnes,
                          hasFulfillment: model.data.data.has_fulfillment,
                          skus: model.data.data.skus });
        }, function(model) {
          defer.reject(model.error);
        });
        return defer.promise;
      },
      isDownloading: function() {
        var defer = $q.defer();
        $http({
          url: '/integrations/is_downloading',
          method: 'GET',
          ignoreLoadingBar: true,
          params: {}
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.error);
        });
        return defer.promise;
      },
      createOrders: function(orders) {
        var defer = $q.defer();
        $http({
          url: '/integrations/push_orders',
          method: 'POST',
          data: {
            orders: orders
          }
        }).then(function(data) {
          defer.resolve(data.data);
        }, function(data) {
          defer.reject(data.data.error);
        });
        return defer.promise;
      },
      sync: function() {
        var defer = $q.defer();
        $http({
          url: '/integrations/download',
          method: 'GET',
          data: {}
        }).then(function(data) {
          defer.resolve(data.data);
        }, function(data) {
          defer.reject(data.data.error);
        });
        return defer.promise;
      },
      getSkusStock: function(hasFulfillment, skus, orders) {
        var rows = [];
        if (hasFulfillment) {
          rows = _.map(orders, function(row, index) {
            var stock = '';
            var skuAndStock = '';
            var provisorySkuStock = 'no existe';
            angular.forEach(row.skus.split(';'), function(orderSkuValue, orderSkuIndex) {
              provisorySkuStock = 'no existe';
              angular.forEach(skus, function(clientSkuValue, clientSkuIndex) {
                if (orderSkuValue.trim() === clientSkuValue.name) {
                  stock += clientSkuValue.amount + '; ';
                  provisorySkuStock = clientSkuValue.amount;
                }
              });
              skuAndStock += orderSkuValue.trim() + ' -> ' + provisorySkuStock + '; ';
            });
            row.stock = stock;
            row.skuAndStockArrayOfArrays = _.map(skuAndStock.split(';'), function(sas) { return sas.split('->'); });
            return row;
          });
        } else {
          rows = orders;
        }
        return rows;
      },
      minimizeApi2CartFields: function(object) {
        var temp_obj_funt = function(obj) {
          var temp = {};
          Object.keys(obj).forEach(function (key) {
            if (key == 'state') {
              temp[key] = '';
              if (obj[key] != null && obj[key] != undefined){
                temp[key] = obj[key].name
              }
            } else {
              temp[key] = obj[key];
            }
          });
          return temp;
        };

        return {
          billing_address: [temp_obj_funt(object.billing_address[0])],
          shipping_address: [temp_obj_funt(object.shipping_address[0])]
        };
      },
      archive: function(order_id, archive) {
        var defer = $q.defer();
        $http({
          url: '/integrations/archive',
          method: 'POST',
          data: {
            order_id: order_id,
            archive: archive
          }
        }).then(function(data) {
          defer.resolve(data.data);
        }, function(data) {
          defer.reject(data.data.error);
        });
        return defer.promise;
      },
      updateOrder: function(order) {
        var defer = $q.defer();
        $http({
          url: '/integrations/' + order._id.$oid + '/update_order',
          method: 'PATCH',
          data: {
            order: order
          }
        }).then(function(data) {
          defer.resolve(data.data);
        }, function(data) {
          defer.reject(data.data.error);
        });
        return defer.promise;
      },
      whereReferencesAndSeller: function(orders) {
        var defer = $q.defer();
        $http({
          url: '/integrations/by_refereneces',
          method: 'POST',
          data: {
            orders: orders
          }
        }).then(function (data) {
          defer.resolve(data.data);
        }, function (data) {
          defer.reject(data.data.error);
        });
        return defer.promise; 
      }

    };
  }]);
}).call(this);