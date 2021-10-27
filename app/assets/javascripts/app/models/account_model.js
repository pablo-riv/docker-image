'use strict';

/**
* @name: Account
* @description: Maintains Account data
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
  this.app.factory('Account', ['$http', '$q', 'BranchOffice', 'RutHelper', function ($http, $q, BranchOffice, RutHelper) {
    return {
      init: function(data) {
        angular.extend(data, { company: data.entity_specific });
        delete data.entity_specific;
        data.company['branch_office'] = BranchOffice.default(data.company.branch_offices);
        var emails = data.company.email_contact;
        if (emails != null) {
          emails = _.map(data.company.email_contact.split(','), function (data, index) {
            return { id: (index + 1), email: data };
          });
        }
        data['tags'] = emails;
        return data;
      },

      new: function() {
        return {
          email: '',
          entity_id: 0,
          id: 0,
          person_id: 0,
          company: {
            about: '',
            business_name: '',
            business_turn: '',
            bill_email: '',
            bill_phone: '',
            bill_address: '',
            address: {
              commune_id: 0,
              complement: '',
              coords: { latitude: 0, longitude: 0 },
              id: 0,
              number: 0,
              package_id: null,
              street: '',
              commune: {
                code: '',
                couriers_availables: {},
                id: 0,
                is_available: false,
                name: '',
                region_id: 0,
              }
            },
            address_id: 0,
            branch_offices: [],
            commercial_business: '',
            contact_name: '',
            email_commercial: '',
            email_contact: '',
            email_domain: '',
            email_notification: '',
            id: 0,
            is_active: false,
            is_default: false,
            logo: '',
            sales_channel: { categories: {}, names: {} },
            name: '',
            phone: '',
            run: '',
            services: [],
            settings: [],
            website: ''
          },
          branch_office: {
            get_to_parking: '',
            parking_isreachable: ''
          },
          person: {
            birthday: '',
            dni: '',
            first_name: '',
            last_name: '',
            gender: '',
            id: 0,
            payment_data: {},
            phone: ''
          }
        };
      },
      find: function(id) {
        var defer = $q.defer();
        $http({
          url: '/accounts/find/',
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

      validSetup: function(data) {
        var error = this.new();
        var valid = true;
        if (data.company.name == '' || data.company.name == undefined) {
          error.company.name = true;
          valid = false;
        } else if (data.company.run == '' || data.company.run == undefined || !RutHelper.validate(data.company.run)) {
          error.company.run = true;
          valid = false;
        } else if (data.company.business_name == '' || data.company.business_name == undefined) {
          error.company.business_name = true;
          valid = false;
        } else if (data.company.business_turn == '' || data.company.business_turn == undefined) {
          error.company.business_turn = true;
          valid = false;
        } else if (data.company.bill_email == '' || data.company.bill_email == undefined) {
          error.company.bill_email = true;
          valid = false;
        } else if (data.company.bill_phone == '' || data.company.bill_phone == undefined) {
          error.company.bill_phone = true;
          valid = false;
        } else if (data.company.bill_address == '' || data.company.bill_address == undefined) {
          error.company.bill_address = true;
          valid = false;
        } else if (data.company.branch_office.parking_isreachable == '' || data.company.branch_office.parking_isreachable == undefined) {
          error.company.branch_office.parking_isreachable = true;
          valid = false;
        } else if (data.person.first_name == '' || data.person.first_name == undefined) {
          error.person.first_name = true;
          valid = false;
        } else if (data.person.last_name == '' || data.person.last_name == undefined) {
          error.person.last_name = true;
          valid = false;
        } else if (data.company.address.street == '' || data.company.address.street == undefined) {
          error.company.address.street = true;
          valid = false;
        } else if (data.company.address.number == '' || data.company.address.number == undefined) {
          error.company.address.number = true;
          valid = false;
        } else if (data.company.address.commune_id == '' || data.company.address.commune_id == undefined) {
          error.company.address.commune_id = true;
          valid = false;
        }
        return { valid: valid, error: error };
      }
    };
  }]);
}).call(this);
