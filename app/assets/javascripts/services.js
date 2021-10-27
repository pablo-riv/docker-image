//  DOCUMENT READY
// ================

$(document).on('turbolinks:load', function() {

  var sendRequest = function(request) {
    var promise = new Promise(function(resolve, reject) {
      $.ajax({
        method: 'POST',
        url: 'fulfillment_request',
        data: {
          request: request
        },
        success: function(data) {
          resolve(data);
        },
        error: function(data) {
          reject(data);
        }
      });
    });
    promise.then(function(data) {
      console.info(data);
      sendResponse('Se ha enviado tu solicitud, pronto nos contactaremos para iniciar el proceso.');
    }, function(data) {
      console.error(data);
      sendResponse('Problemas al enviar tu solicitud favor, intentar más tarde...');
    });
  };

  var sendResponse = function(response) {
    alert(response);
    window.location.href = '/';
  };

  $('#btn-send-request').on('click', function(event) {
    var request = {
      full_name: $('#full-name').val(),
      company_id: $('#company-id').val(),
      email: $('#email').val(),
      phone: $('#phone').val(),
      message: $('#message').val()
    };

    if (request.full_name === '' || request.company_id === '' || request.email === '' || request.phone === '' || request.message === '') {
      alert('Debes ingresar todos los campos');
    } else {
      sendRequest(request);
    }
  });
});
