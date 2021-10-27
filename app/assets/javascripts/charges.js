$(document).on("turbolinks:load", function() {
  $("#charge_type").on("change", function(e) {
    selected_type = $(this).val();
    if(selected_type == "") {
      $("#charges tr.charge").show();
    } else {
      $("#charges tr.charge").hide();
      $("#charges tr." + selected_type + "-charge").show();
    };
  });
});
