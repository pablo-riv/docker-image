$(document).on("turbolinks:load", function () {
  if ($('#how_to_know_shipit_how')[0] != undefined) {
    $($('#how_to_know_shipit_how')[0][0]).attr('disabled', 'disabled');
    $('#how_to_know_shipit_how').select2({ width: '100%' });
    $('#how_to_know_shipit_how + .select2.select2-container.select2-container--default').css({ 'height': '42px', 'padding-top': '7px' });
    $('#how_to_know_shipit_how + .select2.select2-container.select2-container--default > .selection > .select2-selection.select2-selection--single').css({ 'height': '36px' });
  }

  $('#how_to_know_shipit_how').on('change', function() {
    if ($(this).val() == 'Otros') {
      $('#others_field').removeClass('hidden');
    } else {
      $('#others_field').addClass('hidden');
    }
  });

  $('#new_account').on('submit', function (e) {
    e.preventDefault();
    var name = $('#account_company_name').val();
    var email = $('#account_email').val();
    var password = $('#account_password').val();
    var confirmation = $('#account_password_confirmation').val();
    var term = $('#term_of_service').prop('checked');
    var charge = $('#know_base_charge').prop('checked');
    var size = $('#know_size_restriction').prop('checked');
    var howToKnow = $('#how_to_know_shipit_how').val();
    var howToKnowFrom = $('#how_to_know_shipit_from').val();

    if (window.location.pathname == '/accounts/sign_up') {
      if (name == '') {
        $('#account_company_name').parent().addClass('has-danger');
        $('#account_company_name').addClass('form-control-danger');
        $('#form-control-feedback-name').removeClass('hidden');
        return false;
      } else {
        $('#account_company_name').parent().removeClass('has-danger');
        $('#account_company_name').removeClass('form-control-danger');

        $('#account_company_name').parent().addClass('has-success');
        $('#account_company_name').addClass('form-control-success');
        $('#form-control-feedback-name').addClass('hidden');
      }

      if (email == '') {
        $('#account_email').parent().addClass('has-danger');
        $('#account_email').addClass('form-control-danger');
        $('#form-control-feedback-email').removeClass('hidden');
        return false;
      } else {
        $('#account_email').parent().removeClass('has-danger');
        $('#account_email').parent().addClass('has-success');
        $('#account_email').addClass('form-control-success');
        $('#account_email').removeClass('form-control-danger');
        $('#form-control-feedback-email').addClass('hidden');
      }

      if (password == '') {
        $('#account_password').parent().addClass('has-danger');
        $('#account_password').addClass('form-control-danger');
        $('#form-control-feedback-password').removeClass('hidden');
        return false;
      } else {
        $('#account_password').parent().removeClass('has-danger');
        $('#account_password').removeClass('form-control-danger');

        $('#account_password').parent().addClass('has-success');
        $('#account_password').addClass('form-control-success');
        $('#form-control-feedback-password').addClass('hidden');
      }

      if (confirmation == '') {
        $('#account_password_confirmation').parent().addClass('has-danger');
        $('#account_password_confirmation').addClass('form-control-danger');
        $('#form-control-feedback-password-confirmation').removeClass('hidden');
        return false;
      } else {
        $('#account_password_confirmation').parent().removeClass('has-danger');
        $('#account_password_confirmation').removeClass('form-control-danger');

        $('#account_password_confirmation').parent().addClass('has-success');
        $('#account_password_confirmation').addClass('form-control-success');
        $('#form-control-feedback-password-confirmation').addClass('hidden');
      }

      if (password != confirmation) {
        $('#account_password, #account_password_confirmation').parent().addClass('has-danger');
        $('#account_password, #account_password_confirmation').addClass('form-control-danger');
        $('#account_password, #account_password_confirmation').removeClass('hidden');
        $('#form-control-feedback-password, #form-control-feedback-password-confirmation').text('Las contraseñas deben ser iguales');
        return false;
      } else {
        $('#account_password, #account_password_confirmation').parent().removeClass('has-danger');
        $('#account_password, #account_password_confirmation').removeClass('form-control-danger');

        $('#account_password, #account_password_confirmation').parent().addClass('has-success');
        $('#account_password, #account_password_confirmation').addClass('form-control-success');
        $('#form-control-feedback-password, #form-control-feedback-password-confirmation').addClass('hidden');
      }

      if (howToKnow == "" || howToKnow == null) {
        $('#how_to_know_shipit_how').parent().addClass('has-danger');
        $('#form-control-feedback-how-to-know').removeClass('hidden');
        return false;
      } else {
        $('#how_to_know_shipit_how').parent().removeClass('has-danger');
        $('#form-control-feedback-how-to-know').addClass('hidden');
        if (howToKnow == "Otros" && (howToKnowFrom == null || howToKnowFrom == "")) {
          $('#how_to_know_shipit_from').parent().addClass('has-danger');
          $('#form-control-feedback-how-to-know-from').removeClass('hidden');
          return false;
        }
        else {
          $('#how_to_know_shipit_from').parent().removeClass('has-danger');
          $('#form-control-feedback-how-to-know-from').addClass('hidden');
        }
      }

      if (!term) {
        $('#term_of_service').parent().addClass('has-danger');
        $('#form-control-feedback-term').removeClass('hidden');
        return false;
      } else {
        $('#term_of_service').parent().removeClass('has-danger');
        $('#term_of_service').parent().addClass('has-success');
        $('#form-control-feedback-term').addClass('hidden');
      }

      if (!charge) {
        $('#know_base_charge').parent().addClass('has-danger');
        $('#form-control-feedback-charge').removeClass('hidden');
        return false;
      } else {
        $('#know_base_charge').parent().removeClass('has-danger');
        $('#know_base_charge').parent().addClass('has-success');
        $('#form-control-feedback-charge').addClass('hidden');
      }
      if (!size) {
        $('#know_size_restriction').parent().addClass('has-danger');
        $('#form-control-feedback-size').removeClass('hidden');
        return false;
      } else {
        $('#know_size_restriction').parent().removeClass('has-danger');
        $('#know_size_restriction').parent().addClass('has-success');
        $('#form-control-feedback-size').addClass('hidden');
      }
    }

    this.submit();
  });

});