(function() {
  this.app.factory('MailNotification', ['$q', '$http', function($q, $http) {
    return {
      findBy: function(id) {
        var defer = $q.defer();
        $http({
          url: '/mail_notifications/' + id,
          method: 'GET'
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      update: function(mail) {
        var defer = $q.defer();
        $http({
          url: '/mail_notifications/' + mail.id,
          method: 'PUT',
          data: {
            mail_notification: mail
          }
        }).then(function(model) {
          defer.resolve(model.data);
        }, function(model) {
          defer.reject(model.data);
        });
        return defer.promise;
      },
      test: function(mail, emails) {
        var defer = $q.defer();
        $http({
          url: '/mail_notifications/' + mail.id + '/test' ,
          method: 'POST',
          data: {
            emails: emails
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
