'use strict';

/**
* @name: BRANCH OFFICE
* @description: Maintains BRANCH OFFICE data
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
  this.app.factory('BranchOffice', ['$http', '$q', function ($http, $q) {
    return {
      new: function() {
        return {
          'name': '',
          'contact_name': '',
          'phone': '',
          'address': {
            'street': '',
            'number': '',
            'complement': '',
            'commune_id': 0
          },
          'account': {
            'email': '',
            'password': '',
            'password_confirmation': '',
            'person': {
              'first_name': '',
              'last_name': ''
            }
          }
        };
      },

      create: function(data) {
        var defer = $q.defer();
        $http({
          url: '/branch_offices',
          method: 'POST',
          data: {
            branch_office: JSON.stringify(data)
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      update: function(data) {
        console.log(data.id);
        var defer = $q.defer();
        $http({
          url: '/branch_offices/' + data.id,
          method: 'PATCH',
          data: {
            branch_office: JSON.stringify(data)
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      all: function(company) {
        var defer = $q.defer();
        $http({
          url: '/branch_offices/' + company + '/all',
          method: 'GET',
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      valid: function(branchOffice) {
        var valid = true;
        if (branchOffice.name === '' && branchOffice.contact_name === '' && branchOffice.phone === '' &&
            branchOffice.address.street === '' && branchOffice.address.number === '' && branchOffice.address.complement === '' &&
            branchOffice.address.commune_id === 0 && branchOffice.account.email === '' && branchOffice.account.password === '' &&
            branchOffice.account.password_confirmation === '' && branchOffice.account.person.first_name === '' &&
            branchOffice.account.person.last_name === '') {
          valid = false;
        } else if (branchOffice.account.password !== branchOffice.account.password_confirmation) {
          valid = false
        }
        return valid;
      },

      marketPlaceRequest: function(data) {
        var defer = $q.defer();
        $http({
          url: '/branch_offices/marketplace_request',
          method: 'POST',
          data: {
            request: data
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },

      default: function(branchOffices) {
        return _.where(branchOffices, { is_default: true })[0];
      }

    };
  }]);
}).call(this);
