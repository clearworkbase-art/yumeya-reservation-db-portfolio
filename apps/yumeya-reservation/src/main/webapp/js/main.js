//クラスmenu_btnをクリックしたら
$('.menu_btn').on('click', () => {
	//headerタグにクラスonをつけたり消したり
	$('header').toggleClass('on');
});



//スクロールした際の動きを関数でまとめる
function PageTopAnime() {
	var scroll = $(window).scrollTop();
	if (scroll >= 100) {//上から100pxスクロールしたら
		$('#page-top').removeClass('DownMove');//#page-topについているDownMoveというクラス名を除く
		$('#page-top').addClass('UpMove');//#page-topについているUpMoveというクラス名を付与
	} else {
		if ($('#page-top').hasClass('UpMove')) {//すでに#page-topにUpMoveというクラス名がついていたら
			$('#page-top').removeClass('UpMove');//UpMoveというクラス名を除き
			$('#page-top').addClass('DownMove');//DownMoveというクラス名を#page-topに付与
		}
	}
}

// 画面をスクロールをしたら動かしたい場合の記述
$(window).scroll(function () {
	PageTopAnime();
});

$(window).on('load', function () {
	PageTopAnime();
});


// #page-topをクリックした際の設定
$('#page-top').click(function () {
	var scroll = $(window).scrollTop(); //スクロール値を取得
	if (scroll > 0) {
		$(this).addClass('floatAnime');//クリックしたらfloatAnimeというクラス名が付与
		$('body,html').animate({
			scrollTop: 0
		}, 2000, function () {//スクロールの速さ。数字が大きくなるほど遅くなる
			$('#page-top').removeClass('floatAnime');//上までスクロールしたらfloatAnimeというクラス名を除く
		});
	}
	return false;//リンク自体の無効化
});



//スクロールの設定 
$(window).on('scroll load', function () {        /* ページロード時、またはスクロールされた時*/
	var scroll = $(this).scrollTop();            /* 現在のスクロール量を測定 */
	var windowHeight = $(window).height();       /* ウィンドウの高さを測定 */
	$('.fadeIn').each(function () {                /* 「fadeIn」のクラスがついているものを1つずつ確認し・・・ */
		var cntPos = $(this).offset().top;         /* 対象の要素の上からの距離を測定 */
		if (scroll > cntPos - windowHeight + windowHeight / 3) {  /* 要素がある位置までスクロールされていたら */
			$(this).addClass('active');              /* 「active」のクラスを付与 */
		}
	});
});


// 時間の指定
var timer = 5000;
// スライドする要素を取得
var imgs = document.querySelectorAll('#slider img');
// 最初の画像を表示
imgs[0].classList.add('show');
// 画像の番号
var imgNum = 0;
function showImg() {
	for (var i = 0; i < imgs.length; i++) {
		imgs[i].classList.remove('show');
	}
	if (imgNum >= imgs.length - 1) {
		imgNum = 0;
	} else {
		imgNum++;
	}
	imgs[imgNum].classList.add('show');
	showImgTimer();
}
function showImgTimer() {
	setTimeout(showImg, timer);
}
showImgTimer()



/* headerナビ */
$(".hover").mouseleave(
	function () {
		$(this).removeClass("hover");
	}
);


$('.slider').slick({
	arrows: false,//左右の矢印はなし
	autoplay: true,//自動的に動き出すか。初期値はfalse。
	autoplaySpeed: 0,//自動的に動き出す待ち時間。初期値は3000ですが今回の見せ方では0
	speed: 5000,//スライドのスピード。初期値は300。
	infinite: true,//スライドをループさせるかどうか。初期値はtrue。
	pauseOnHover: false,//オンマウスでスライドを一時停止させるかどうか。初期値はtrue。
	pauseOnFocus: false,//フォーカスした際にスライドを一時停止させるかどうか。初期値はtrue。
	cssEase: 'linear',//動き方。初期値はeaseですが、スムースな動きで見せたいのでlinear
	slidesToShow: 4,//スライドを画面に4枚見せる
	slidesToScroll: 0.5,//1回のスライドで動かす要素数
	// swipeToSlide: false,
	// swipe: true,
	// touchMove: true,
	// touchThreshold: 5,
	responsive: [
		{
			breakpoint: 769,//モニターの横幅が769px以下の見せ方
			settings: {
				slidesToShow: 2,//スライドを画面に2枚見せる
			}
		},
		{
			breakpoint: 426,//モニターの横幅が426px以下の見せ方
			settings: {
				slidesToShow: 1.5,//スライドを画面に1.5枚見せる
			}
		}
	]
});


console.log('haro');


