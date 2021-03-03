$('#space_customer_create_flag_false').on('click', function() {
    if ($('#space_customer_code').hasClass("is-valid")) {
        $('#space_customer_code').removeClass("is-valid");
        $('#space_customer_code').addClass("is-invalid");
    }
    $('#space_customer_code_area').removeClass("collapse");
    $('#space_customer_name_area').addClass("collapse");
});
$('#space_customer_create_flag_true').on('click', function() {
    if ($('#space_customer_name').hasClass("is-valid")) {
        $('#space_customer_name').removeClass("is-valid");
        $('#space_customer_name').addClass("is-invalid");
    }
    $('#space_customer_name_area').removeClass("collapse");
    $('#space_customer_code_area').addClass("collapse");
});
