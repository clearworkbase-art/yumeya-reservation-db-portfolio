


$(function () {
    $('#subImg1 img').on('click', function () {
        //mainに切り替えるimgのsrc取得
        img = $(this).attr('src');
        //currentクラス付け替え
        $('#subImg1 li').removeClass('current');
        $(this).parent().addClass('current');
        //fadeOutできたらsrc変更してfadeIn
        $('#mainImg1 img').fadeOut(50, function () {
            $('#mainImg1 img').attr('src', img).on('load', function () {
                $(this).fadeIn();
            })
        })
    });
});



$(function () {
    $('#subImg2 img').on('click', function () {
        //mainに切り替えるimgのsrc取得
        img = $(this).attr('src');
        //currentクラス付け替え
        $('#subImg2 li').removeClass('current');
        $(this).parent().addClass('current');
        //fadeOutできたらsrc変更してfadeIn
        $('#mainImg2 img').fadeOut(50, function () {
            $('#mainImg2 img').attr('src', img).on('load', function () {
                $(this).fadeIn();
            })
        })
    });
});


$(function () {
    $('#subImg3 img').on('click', function () {
        //mainに切り替えるimgのsrc取得
        img = $(this).attr('src');
        //currentクラス付け替え
        $('#subImg3 li').removeClass('current');
        $(this).parent().addClass('current');
        //fadeOutできたらsrc変更してfadeIn
        $('#mainImg3 img').fadeOut(50, function () {
            $('#mainImg3 img').attr('src', img).on('load', function () {
                $(this).fadeIn();
            })
        })
    });
});