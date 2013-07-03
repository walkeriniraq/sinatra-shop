(function () {
    "use strict";
    function BooksMain() {
        var self = this;
        self.current_list = ko.observableArray();
        self.user = ko.observable();
        self.current_page = ko.observable();
        self.total_pages = ko.observable();
        self.has_next_page = ko.computed(function () {
            return self.current_page() < self.total_pages();
        });
        self.has_prev_page = ko.computed(function () {
            return self.current_page() > 1;
        });
        self.logged_in = ko.computed(function () {
            return !!self.user();
        });
        self.load_data = function (page) {
            $.getJSON('list', { page: page }, function (data) {
                self.current_list(data.list);
                self.total_pages(data.total_pages);
                self.current_page(data.current_page);
                History.pushState(null, null, '?page=' + data.current_page);
            });
        };
        self.next_page = function () {
            self.load_data(self.current_page() + 1);
            return false;
        };
        self.previous_page = function () {
            self.load_data(self.current_page() - 1);
            return false;
        };
    }

    window.books_main = new BooksMain();

    function get_page() {
        var regex_result = new RegExp('=\\d+$').exec(window.History.getState().url);
        if (!regex_result) {
            return 1;
        }
        return parseInt(regex_result[0].substring(1), 10);
    }

    $(function () {
        ko.applyBindings(window.books_main);
        window.books_main.load_data(get_page());
        $.getJSON('username', function (data) {
            if (data.status === 'ok') {
                window.books_main.user(data.user);
            }
        });
        $(window).on('statechange', function () {
            var page = get_page();
            if (page !== window.books_main.current_page()) {
                window.books_main.load_data(page);
            }
        });
        $('#prev_page').click(window.books_main.previous_page);
        $('#next_page').click(window.books_main.next_page);
    });
}());