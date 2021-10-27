$(document).on('turbolinks:load', function() {

  var maxFields = 5000;
  var wrapper = $('.input_fields_wrap');
  var add_button = $('.add_field_button');
  var x = 1;
  var id = 0;

  var findSku = function(sku) {
    var promise = new Promise(function(resolve, reject) {
      $.ajax({
        url: '/packages/find_sku/' + sku,
        method: 'GET',
        success: function(data) {
          resolve(data);
        },
        error: function(data) {
          console.warn(data);
          reject(data);
        }
      });
    });
    promise.then(function(sku) {
      $('#stock').val(sku.amount);
      $('#description').val(sku.description);
      return sku;
    }, function(error) {
      console.error(error);
    });
  };

  var addSkuFields = function(sku, type) {
    if (type === 'massive' && $('#sku-' + sku.sku).length > 0) {
      x -= 1; id -= 1;
      $('#sku-' + sku.sku).remove();
    }

    $(wrapper).append(
      '<div class="row pt-30" id="sku-' + sku.sku + '">'
      + '<div class="col-md-3">'
        + '<input type="hidden" class="sku-id" value=' + sku.sku + ' name="package[inventory_activity][inventory_activity_orders_attributes][' + sku.id + '][sku_id]"/>'
        + '<input class="form-control sku-name" type="text" name="mytext[' + sku.id + ']" disabled value="' + sku.name + '"/>'
      + '</div>'
      + '<div class="col-md-2">'
        + '<input class="form-control sku-quantity" type="text" value="' + sku.quantity + '" name="package[inventory_activity][inventory_activity_orders_attributes][' + sku.id + '][amount]" readonly/>'
      + '</div>'
      + '<div class="col-md-2">'
        + '<input class="form-control" type="text" value="' + sku.stock + '" name="" readonly/>'
      + '</div>'
      + '<div class="col-md-4">'
        + '<input class="form-control" type="text" value="' + sku.description + '" name="" readonly/>'
      + '</div>'
      + '<div class="col-md-1 mt-5">'
        + '<a href="#" class="red remove_field"> Quitar</a>'
      + '</div>'
      +'</div>');
  };

  var filterCommunes = function(regionName) {
    $.ajax({
      url: 'filter_communes',
      method: 'GET',
      data: { region_name: regionName },
      success: function(data) {
        $('#package_address_attributes_commune_id').empty();
        $.each(data, function(index, value) {
          $('#package_address_attributes_commune_id').append('<option value="'+ value.id +'">' + value.name + '</option>');
        });
        $('#package_address_attributes_commune_id').select2();
      },
      error: function(data) {
        console.info(data);
      }
    });
  };

  var checkoutOrder = function(package, self) {
    if (package.fullName === '') {
      alert('Debes ingresar Nombre Destinatario');
    } else if (package.street === '') {
      alert('Debes ingresar Calle');
    } else if (package.number === '') {
      alert('Debes ingresar Número de Calle');
    } else if (package.commune === '') {
      alert('Debes seleccionar Comuna');
    } else if (package.courier_for_client === 'chilexpress' && package.destiny === 'Starken-Turbus') {
      alert('No puedes seleccionar courier Chilexpress y enviar a Starken');
    } else if (package.courier_for_client === 'starken' && package.destiny === 'Chilexpress') {
      alert('No puedes seleccionar courier Starken y enviar a Chilexpress');
    } else if (package.destiny === '') {
      alert('Debes seleccionar Domicilio / Sucursal');
    } else if (package.approxSize === '') {
      alert('Debes seleccionar Tamaño Aproximado');
    } else if (package.itemsCount === '' && $(self).data('hasFulfillment') === false) {
      alert('Debes ingresar cantidad de items');
    } else if (package.reference === '') {
      alert('Debes ingresar Referencia');
    } else if (package.courier_for_client === 'chilexpress' && package.destiny === 'Domicilio' && package.is_payable == true) {
      alert('No puedes realizar envíos por pagar a domicilio y con courier Chilexpress');
    } else {
      $('#table-sku tbody').empty();
      if ($(self).data('hasFulfillment') === true) {
        package.itemsCount = 0;
        x -= 1;
        for (var i = 0; i < x; i++) {
          package.itemsCount += parseInt($('input[name="package[inventory_activity][inventory_activity_orders_attributes][' + i + '][amount]"]').val());
          console.info('PACKAGE COUNT: ' + package.itemsCount + '\nX: ' + x + '\nID: ' + id);
          $('#table-sku tbody').append('<tr>'
            + '<td id="order-number">' + (i + 1) + '</td>'
            + '<td id="order-sku-name">' + $('input[name="mytext[' + i + ']"]').val() + '</td>'
            + '<td id="order-sku-quantity">' + $('input[name="package[inventory_activity][inventory_activity_orders_attributes][' + i + '][amount]"]').val() + '</td>'
            +'</tr>');
        }
        x += 1;
        package.packing = 'Sin Empaque';
        $('form').append('<input type="hidden" name="package[items_count]" value="'+ package.itemsCount +'">');
        $('form').append('<input type="hidden" name="package[packing]" value="'+ package.packing +'">');
      }
      if (package.itemsCount > 0) {
        $('#order-name').text('Nombre Destinatario: ' + package.fullName);
        $('#order-email').text('Correo Electrónico: ' + $('#package_email').val());
        $('#order-address').text('Dirección Entrega: ' + package.street + ' '+ package.number + ', ' + package.commune);
        $('#order-phone').text('Teléfono: ' + package.cellphone);
        $('#order-reference').text(package.reference);
        $('#order-packing').text(package.packing);
        $('#order-destiny').text(package.destiny);
        $('#order-items-count').text(package.itemsCount);
        $('#checkout-order').modal('show');
      } else {
        alert('Debes Agregar cantidad de productos y/o no has agregado SKU');
      }
    }
  };

  var templateSku = function() {
    return { 'name': '', 'amount': 0, 'min_amount': 0, 'description': '', company_id: '' };
  };

  var displaySkus = function(workbook) {
    var sheet = workbook.SheetNames[0];
    $('#table-skus').fadeIn();
    window.skus = [], count = 0, worksheet = workbook.Sheets[sheet], sku = templateSku();
    console.info(worksheet);
    $.each(worksheet, function(index, value, c) {
      count++;
      if (!['!ref', 'A1', 'B1'].includes(index)) {
        switch (index.substring(0, 1)) {
          case 'A':
            sku.name = value.v;
            break;
          case 'B':
            sku.amount = parseInt(value.v);
            if (sku.amount > 0) {
              if (!isNaN($('#btn-skus-xls').data('companyId')) || $('#btn-skus-xls').data('companyId') !== '') {
                sku.company_id = parseInt($('#btn-skus-xls').data('companyId'));
                window.skus.push(sku);
                $('#btn-skus-xls').removeAttr('disabled');
                loadTableData(sku);
                sku = templateSku();
              } else {
                alert('Te pillamos pos compadre... se recargara la pagina...');
                window.location.reload(true);
              }
            } else {
              alert('La cantidad y la cantidad mínima del SKU ' + sku.name + ' deben ser mayor que 0, favor corregir.');
              sku = templateSku();
            }
            break;
          default:
            break;
        }
      }
    });
  };

  var loadTableData = function(sku) {
    $('#table-skus tbody').delay(2500).append(
      '<tr class="animated fadeIn">'
        + '<td>'+ ($('#table-skus tbody tr').length + 1)+'</td>'
        + '<td>'+ sku.name +'</td>'
        + '<td class="text-center">'+ sku.amount +'</td>'
      + '</tr>');
  };

  var loadAllCompanySku = function() {
    return validateSku($('#sku').data('skus'));
  };

  var validateSku = function(companySkus) {
    if (window.skus.length > 0 && companySkus.length > 0) {
      $.each(window.skus, function(index, value) {
        var data = companySkus.containsByProp('name', value.name);
        if (data.result) {
          if (parseInt(value.amount) > 0 && (parseInt(data.sku.amount) >= parseInt(value.amount))) {
            if(x < maxFields) {
              x++;
              addSkuFields({ sku: data.sku.id, id: index, name: data.sku.name, quantity: value.amount, stock: (data.sku.amount - value.amount), description: data.sku.description }, 'massive');
              $('#sku option[value="' + data.sku.id + '"]').remove(); $('#qty').val(''); $('#stock').val(''); $('#description').val('');
              id++;
            }
          } else {
            alert('La cantidad ingresada del SKU ' + data.sku.name + ' es mayor que el stock disponible \n Cantidad disponible: ' + parseInt(data.sku.amount) + '\n Cantidad ingresada: ' + value.amount + '\n');
          }
        } else {
          $('#table-name-' + value.name.replace(/ /g, '')).remove();
          $('#error-message-log').append(
            '<div class="alert alert-danger alert-dismissible animated fadeIn" role="alert">'
              + '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>'
              + '<strong class="">El Sku: ' + value.name + ' no se encuentra en nuestros registros, favor eliminar del archivo y volver a cargar.</strong>'
            + '</div>');
        }
      });
      if ($('#error-message-log').children().length > 0) {
        $('#error-message-log').removeClass('hidden');
        $('#btn-skus-xls').attr('disabled', 'disabled');
      } else {
        $('#massive-skus').modal('hide');
      }
    } else {
      alert('No encontramos Skus disponibles');
    }
  };

  $('form#new_package select').select2({
    width: '100%'
  });
  $('#btnSave').click(function() {
    addCheckbox("hola");
  });

  $('#sku').select2({ placeholder: 'Seleccionar Sku' });
  $('#sku').on('change', function() {
    var sku = findSku($("#sku :selected").val());
  });

  $('#massive-skus').on('hidden.bs.modal', function() {
    $('#table-skus tbody').empty();
    $('#select-xlsx').val('');
  });

  $('#select-xlsx').on('change', function(e) {
    $('#table-skus tbody').empty();
    $('#error-message-log').empty();
    $('#error-message-log').addClass('hidden');
    var files = e.target.files;
    var i, f;
    for (i = 0, f = files[i]; i != files.length; ++i) {
      var reader = new FileReader();
      var name = f.name;
      reader.onload = function(e) {
        var data = e.target.result;
        var workbook = XLSX.read(data, { type: 'binary' });
        displaySkus(workbook);
      };
      reader.readAsBinaryString(f);
    };
  });

  $('#btn-skus-xls').click(function(event) {
    event.preventDefault();
    $('#select-xlsx').val('');
    if (window.skus !== undefined && window.skus.length > 0) {
      loadAllCompanySku(parseInt($(this).data('companyId')));
    } else {
      alert('Debes agregar al menos un sku antes de enviar.');
      $('#massive-skus').modal('hide');
    };
  });

  $(add_button).click(function(e) {
    e.preventDefault();
    var quantity = parseInt($('#qty').val());
    var stock = parseInt($('#stock').val());
    var minStock = parseInt($('#min-stock').val());
    if (quantity > 0 && stock >= quantity) {
      if(x < maxFields) {
        x++;
        addSkuFields({
          sku: $('#sku').val(),
          id: id,
          name: $('#sku :selected').text(),
          quantity: $('#qty').val(),
          stock: (parseInt($('#stock').val()) - parseInt($('#qty').val())),
          description: $('#description').val()
        }, 'normal');
        $('#sku option[value="' + $('#sku').val() + '"]').remove(); $('#qty').val(''); $('#stock').val(''); $('#description').val('');
        id++;
      } else {
        alert('Ya no puedes ingresar más SKUs');
      }
    } else {
      alert('La cantidad debe ser mayor que 0 y debe ser menor igual al stock disponible.');
    }
  });

  $(wrapper).on('click', '.remove_field', function(event) {
    event.preventDefault();
    $("#sku").append('<option value=' + $(this).parent('div').parent('div')[0].children[0].children[0].value + '>' + $(this).parent('div').parent('div')[0].children[0].children[1].value + '</option>');
    $(this).parent('div').parent('div').remove(); x--; id--;
    $.each($('.input_fields_wrap').children(), function(index, value) {
      var quantity = $(value).children().find('.sku-quantity');
      var skuId = $(value).children().find('.sku-id');
      var skuName = $(value).children().find('.sku-name');
      $($(quantity)[0]).attr('name', 'package[inventory_activity][inventory_activity_orders_attributes][' + index + '][amount]')
      $($(skuId)[0]).attr('name', 'package[inventory_activity][inventory_activity_orders_attributes][' + index + '][sku_id]')
      $($(skuName)[0]).attr('name', 'mytext[' + index + ']');
    });
  });

  $('form').bind('submit', function () {
    $(this).find('#package_destiny').prop('disabled', false);
    $(this).find('#package_packing').prop('disabled', false);
  });

  $('#package_courier_for_client').on('change', function(event) {
    var data = [];
    if ($('#package_courier_for_client').val() == 'chilexpress' && $('#package_is_payable').is(':checked') == true) {
      data  = [{id: 'Chilexpress', text: 'Chilexpress'}];
    } else if ($('#package_courier_for_client').val() == 'chilexpress') {
      data  = [{id: 'Chilexpress', text: 'Chilexpress'}, {id: 'Domicilio', text: 'Domicilio'}];
    } else if ($('#package_courier_for_client').val() == 'starken') {
      data = [{id: 'Starken-Turbus', text: 'Starken-Turbus'}, {id: 'Domicilio', text: 'Domicilio'}]
    } else {
      data  = [{id: 'Chilexpress', text: 'Chilexpress'}, {id: 'Starken-Turbus', text: 'Starken-Turbus'}, {id: 'Domicilio', text: 'Domicilio'}]
    }
    fillDestiniesOptions(data);
  });

  $('#package_destiny').on('change', function(event) {
    if ($(this).val() == 'Domicilio' && $('#package_courier_for_client').val() == 'chilexpress' && $('#package_is_payable').is(':checked') == true) {
      cleanfields();
      alert('No puedes realizar envíos por pagar a domicilio y con courier Chilexpress');
    } else if ($(this).val() == 'Chilexpress' && $('#package_courier_for_client').val() == 'starken') {
      alert('No puedes realizar envíos por Starken y enviar a Sucursal Chilexpress');
      cleanfields();
    } else if ($(this).val() == 'Starken-Turbus' && $('#package_courier_for_client').val() == 'chilexpress') {
      alert('No puedes realizar envíos por Chilexpress y enviar a Sucursal Starken');
      cleanfields();
    }
  });

  $('#package_is_payable').on('change', function(event) {
    var data = [];
    if ($(this).is(':checked') == true) {
      if ($('#package_destiny').val() === 'Domicilio' && $('#package_courier_for_client').val() === 'chilexpress') {
        $(this).removeAttr('checked');
        alert('No puedes realizar envíos por pagar a domicilio y con courier Chilexpress');
      } else {
        fillDestiniesOptions([{id: 'Chilexpress', text: 'Chilexpress'}, {id: 'Starken-Turbus', text: 'Starken-Turbus'}, {id: 'Domicilio', text: 'Domicilio'}]);
      }
    } else {
      fillDestiniesOptions([{id: 'Chilexpress', text: 'Chilexpress'}, {id: 'Starken-Turbus', text: 'Starken-Turbus'}, {id: 'Domicilio', text: 'Domicilio'}]);
    }
  });

  var fillDestiniesOptions = function(data) {
    $('#package_destiny option').remove();
    $.each(data, function(index, value) {
      $('#package_destiny').append('<option value=' + value.id + '>' + value.text + '</option>')
    });
    $('#package_destiny').select2();
  };

  var fillCourierOptions = function(data) {
    $('#package_courier_for_client option').remove();
    $.each(data, function(index, value) {
      $('#package_courier_for_client').append('<option value=' + value.id + '>' + value.text + '</option>')
    });
    $('#package_courier_for_client').select2();
  };

  var cleanfields = function() {
    $('#package_is_payable').removeAttr('checked');
    $('#package_courier_for_client').val('');
    $('#package_destiny').val();
  };

  $('#btn-checkout-order').click(function(event) {
    event.preventDefault();
    checkoutOrder({
      fullName: $('#package_full_name').val(),
      street: $('#package_address_attributes_street').val(),
      number: $('#package_address_attributes_number').val(),
      commune: $('#package_address_attributes_commune_id option:selected').text(),
      destiny: $('#package_destiny option:selected').text(),
      courier_for_client: $('#package_courier_for_client option:selected').text(),
      shippingType: $('#package_shipping_type option:selected').text(),
      approxSize: $('#package_approx_size option:selected').text(),
      packing: $('#package_packing option:selected').text(),
      itemsCount: $('#package_items_count').val(),
      reference: $('#package_reference').val(),
      is_payable: $('#package_is_payable').is(':checked'),
      cellphone: $('#package_address_attributes_cellphone').val()

    }, this);
  });

  $('#package_shipping_type').on('change', function(event) {
    var destiny = $('#package_destiny');
    var packing = $('#package_packing');
    // if (this.value === 'Mismo día') {
    //   destiny.val('Domicilio').trigger('change');
    //   destiny.attr('disabled', 'disabled');
    //   packing.val('Sin empaque').trigger('change');
    //   packing.attr('disabled', 'disabled');
    //   filterCommunes('Metropolitana');
    // } else {
    //   destiny.val('').trigger('change');
    //   destiny.removeAttr('disabled');
    //   packing.val('').trigger('change');
    //   packing.removeAttr('disabled');
    //   filterCommunes('');
    // };
    destiny.val('').trigger('change');
    destiny.removeAttr('disabled');
    packing.val('').trigger('change');
    packing.removeAttr('disabled');
  });

  $('#operation-help').popover();
  setTimeout(function() {
    $('.state-tooltip').tooltip();
    $('.operation-help').popover();
  }, 1000);
  $('#status').select2();
  $('#by_status').select2();
  $('#from_courier').select2();
  $('#package_address_attributes_commune_id').select2();
  $('#approx_size').select2();
  $('#package_courier_for_client').select2();
  $(".datepicker-input").datepicker({ language: 'es', orientation: 'bottom' });
  $('#from_date, #to_date, #status').on('change', function(event) {
    $('.download-button').hide();
  });
});
