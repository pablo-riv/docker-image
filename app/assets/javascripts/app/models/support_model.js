(function() {
  this.app.factory('Support', ['$q', '$http', function($q, $http) {
    return {

      new: function(data) {
        return {
          package_id: data.id,
          subject: '',
          kind: '',
          priority: '',
          messages: [{message: '', created_at: new Date(), user: 'end_user' }],
          package_reference: data.reference,
          other_subject: '',
          package_tracking: data.tracking_number
        }
      },

      all: function(status) {
        var defer = $q.defer();
        $http({
          url: '/helps/supports',
          method: 'GET',
          params: { status: status }
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
          url: '/helps/find',
          method: 'GET',
          params: { provider_id: id }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      update: function(support) {
        var defer = $q.defer();
        $http({
          url: '/helps',
          method: 'PATCH',
          data: { support: support }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      create: function(support) {
        var defer = $q.defer();
        $http({
          url: '/helps',
          method: 'POST',
          data: { support: support }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      syncronize: function() {
        var defer = $q.defer();
        $http({
          url: '/helps/syncronize',
          method: 'POST'
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      submitMessage: function(message, ticketId) {
        var defer = $q.defer();
        $http({
          url: '/v/zendesk/submit_message',
          method: 'POST',
          data: {
            message: message,
            ticket_id: ticketId
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      }
    };
  }]);
}).call(this);
