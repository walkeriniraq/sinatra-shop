(function () {
    "use strict";
    function BooksDetail() {
        var self = this;
        self.favorite = ko.observable();
        self.username = ko.observable();

        self.change_favorite = function (add_fav, title_id) {
            var url = '../remove_favorite';
            if (add_fav) {
                url = '../add_favorite';
            }
            $.post(url, { title_id: title_id }, function (data) {
                if (data.status === 'ok') {
                    self.favorite(add_fav);
                } else {
                    alert(data.status);
                }
            }, 'json');
        };
    }

    window.details = new BooksDetail();

    $(function () {
        ko.applyBindings(window.details);
        $('#remove_from_favs').click(function () {
            window.details.change_favorite(false, $(this).data('title-id'));
        });
        $('#add_to_favs').click(function () {
            window.details.change_favorite(true, $(this).data('title-id'));
        });
    });
}());