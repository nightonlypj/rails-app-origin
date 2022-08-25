// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
require('jquery')

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

const debug = $("meta[name='debug']").attr('content') === 'true'
let leftMenuDisplay = null

$(document).on('turbolinks:load', function(){
    if (debug) console.log('== turbolinks:load', leftMenuDisplay)

    changeLeftMenuDisplay(leftMenuDisplay == null || leftMenuDisplay)

    // 左メニュー表示切り替えボタンクリック
    $('#left_menu_display_btn').on('click', function() {
        if (debug) console.log('== #left_menu_display_btn.onclick', leftMenuDisplay)

        leftMenuDisplay = !leftMenuDisplay
        changeLeftMenuDisplay()
    });

    // 画面サイズ変更 -> 左メニュー表示切り替え
    $(window).on('resize', function() {
        if (debug) console.log('== onresize', leftMenuDisplay)

        changeLeftMenuDisplay(true)
    });

    // 左メニュー表示切り替え
    function changeLeftMenuDisplay(autoUpdate = false) {
        if (autoUpdate) leftMenuDisplay = document.body.clientWidth >= 1264 // Tips: md(Medium)以下はメニューを閉じる
        $('#left_menu').css('display', leftMenuDisplay ? 'block' : 'none')
    }
})
