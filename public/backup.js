$(document).ready(function() {

    if(localStorage)
    {
        if(localStorage.backup)
            $("#entry").val(localStorage.backup);

        $("#entry").keyup(function(){
            localStorage.setItem('backup', $(this).val());
        });

        if($("#saved").val() == 1)
        { 
            $("#entry").val('');
            $("#saved").val('');
            localStorage.clear();
        }
    }
});
