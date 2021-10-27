//  DOCUMENT READY
// ================

$(document).on('turbolinks:load', function() {
  $('#company_address_commune_id').select2();
  $('#cxp_prices_modal, #stk_prices_modal, #cc_prices_modal').on('click', function(event) {
    configurLuncheModal(this.id);
  });
  $('#confirm-couriers').on('click', function(event) {
    $('.btn-container-place').empty();
    var values = $('input[name="setting[courier]"]').map(function() {
      if (typeof this.value == 'string' && this.checked) {
        $('.btn-container-place').append(insertModalTrigger(this.value));
      };
    });
    $('#cxp_prices_modal, #stk_prices_modal, #cc_prices_modal').on('click', function(event) {
      configurLuncheModal(this.id);
    });
    $('#prices').removeClass('hidden');
  });

  var configurLuncheModal = function(id) {
    switch (id) {
      case 'cxp_prices_modal':
        $('#modal-title-prices').text('Chilexpress');
        $('#csv-cxp').removeClass('hidden');
        $('#csv-cc, #csv-stk').addClass('hidden');
        $('#courier-id').val(1);
        break;
      case 'stk_prices_modal':
        $('#modal-title-prices').text('Starken');
        $('#csv-stk').removeClass('hidden');
        $('#csv-cc, #csv-cxp').addClass('hidden');
        $('#courier-id').val(2);
        break;
      case 'cc_prices_modal':
        $('#modal-title-prices').text('Correos de Chile');
        $('#csv-cc').removeClass('hidden');
        $('#csv-stk, #csv-cxp').addClass('hidden');
        $('#courier-id').val(3);
        break;
      default:
        break;
    };
  };

  var insertModalTrigger = function(name) {
    var courierName = '', className='';
    switch (name) {
      case 'cxp': courierName = 'Chilexpress', className = 'warning'
        break;
      case 'stk': courierName = 'Starken', className = 'success'
        break;
      case 'cc': courierName = 'Correos Chile', className = 'danger'
        break;
      default:
      break;
    };
    return '<button class="btn btn-outline-' + className + ' m-r-xs m-b-xs" data-toggle="modal" data-target=".modal-prices" id="' + name + '"_prices_modal">Cargar Precios ' + courierName + ' </button>';
  };

  $('#CXP_prices, #STK_prices, #CC_prices').on('change click', function(event) {
    $(".table-container").empty();
    var file = null, data = null, reader = new FileReader();
    if (!validateBrowser()) {
      alert('Debes tener un navegador moderno para poder utilizar nuestras funciones');
    } else {
      file = event.target.files[0];
      if (file != undefined && file != null) {
        reader.readAsText(file);
        reader.onload = function(event) {
          var csvData = event.target.result;
          data = $.csv.toObjects(csvData);
          if (data && data.length > 0) {
            $('.table-container').append(tableTemplate(data));
          } else {
            console.error('No data to import!');
          };
        };
        reader.onerror = function() {
          console.error('Unable to read ' + file.fileName);
        };
      }
    };
  });

  var validateBrowser = function() {
    var isCompatible = false;
    if (window.File && window.FileReader && window.FileList && window.Blob) {
      isCompatible = true;
    };
    return isCompatible;
  };

  var tableTemplate = function(data) {
    var template = "<table class='table table-striped table-bordered'>"
                 + "   <thead>"
                 + "     <tr>";
    for (var i = 0; i < Object.keys(data[0]).length; i++) {
      template   += "      <th>" + Object.keys(data[0])[i] + "</th>";
    };
    template     += "    </tr>"
                +  "  </thead>"
                +  "  <tbody>";
    for (var i = 0; i < data.length; i++) {
      template     +=  "    <tr>";
      for (var j = 0; j < Object.keys(data[i]).length; j++) {
        template   += "       <td>" + data[i][Object.keys(data[i])[j]] + "</td>";
      };
      template     += "    </tr>";
    };
    template     += "  </tbody>"
                 + "</table>";
    return template;
  };

  var path = window.location.pathname.split("/");
  if (path[path.length -1] === "assigns") {
    var list = $(".gsi-step-indicator li").removeClass("current");
    switch (parseInt(window.location.search.substring(6, 7))) {
      case 1:
        $(".step-2, .step-3, .step-0").removeClass("active");
        $(".step-1").addClass("active");
        $(list[1]).addClass("current");
        break;
      case 2:
        $(".step-1, .step-3, .step-0").removeClass("active");
        $(".step-2").addClass("active");
        $(list[2]).addClass("current");
        break;
      case 3:
        $(".step-1, .step-2, .step-0").removeClass("active");
        $(".step-3").addClass("active");
        $(list[3]).addClass("current");
        break;
      default:
        $(".step-1, .step-2, .step-3").removeClass("active");
        $(".step-0").addClass("active");
        $(list[0]).addClass("current");
        break;
    };
  };

  var getCourierPrices = function() {
    var path = window.location.pathname.split("/");
    if (path[path.length - 1] == "prices") {
      $.ajax({
        url: "couriers",
        method: "GET",
        format: "json",
        success: function(data) {
          $.each(data, function() {
          });
        },
        error: function(data) {
        }
      });
    };
  };

  $(".webhook_toggle").on("click", function(event){
    var hide = $(this).is(":checked") ? true : false
    $(".webhook_form").removeClass("hidden").toggle(hide);
  });
});
