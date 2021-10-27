(function() {
  this.app.service('OrderService', function() {
    return{
      verifyEmailFormat: function(customer_email) {
        if (customer_email === undefined) {
          alert('El correo ingresado no tiene un formato válido');
          return false;
        }
        if (customer_email === '') {
          var option = confirm('El correo ingresado está vacío, ¿deseas guardarlo?');
          if (option === false) {
            return false;
          }
        }
        return true;
      }
    }
  });
}).call(this)
