(function () {
    "use strict";
    function BooksLogin() {
        var self = this;
        self.user_list = ko.observableArray();
        self.selected_user = ko.observable();
    }

    window.login = new BooksLogin();
    $(function () {
        ko.applyBindings(window.login);
        $.getJSON('user_list', function (data) {
            window.login.user_list(data);
        });
        $('#login_button').click(function () {
            $.post('login', { username: window.login.selected_user().username }, function (data) {
                if (data.status === 'ok') {
                    $(location).attr('href', '.')
                } else {
                    alert(data.status);
                }
            }, 'json');
        });
    });
}());