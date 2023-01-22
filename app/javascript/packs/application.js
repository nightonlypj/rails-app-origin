// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require('@rails/ujs').start()
require('turbolinks').start()
require('@rails/activestorage').start()
require('channels')
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

    updateDisplay(leftMenuDisplay == null || leftMenuDisplay)

    // 左メニュー表示切り替えボタンクリック
    $('#left_menu_display_btn').on('click', function() {
        if (debug) console.log('== #left_menu_display_btn.onclick', leftMenuDisplay)

        leftMenuDisplay = !leftMenuDisplay
        updateDisplay()
    })

    // 画面サイズ変更 -> 左メニュー表示切り替え
    $(window).on('resize', function() {
        if (debug) console.log('== onresize', leftMenuDisplay)

        updateDisplay(true)
    })
})

function updateDisplay(autoUpdate = false) {
    const clientWidth = document.body.clientWidth

    // 左メニュー表示切り替え
    if (autoUpdate) leftMenuDisplay = clientWidth >= 1264 // NOTE: md(Medium)以下はメニューを閉じる
    if (debug) console.log('#left_menu.display: ' + autoUpdate + ' + (' + clientWidth + ' >= 1264) = ' + leftMenuDisplay)
    $('#left_menu').css('display', leftMenuDisplay ? 'block' : 'none')

    // アプリ名の最大幅（省略の為）
    const areaWidth = leftMenuDisplay ? $('#nav_area').width() : clientWidth
    const navLeftWidth = $('#nav_left').width()
    const appLogoWidth = $('#app_logo').width()
    const navRightWidth = $('#nav_right').width()
    const marginWidth = leftMenuDisplay ? 20 : 28
    const appNameWidth = areaWidth - navLeftWidth - appLogoWidth - navRightWidth - marginWidth
    if (debug) console.log('#app_name.max-width: ' + areaWidth + ' - ' + navLeftWidth + ' - ' + appLogoWidth + ' - ' + navRightWidth + ' - ' + marginWidth + ' = ' + appNameWidth)
    $('#app_name').css('max-width', Math.floor(appNameWidth) + 'px')
    $('#main_contents').css('min-width', ((clientWidth < 600 ? Math.floor(clientWidth) : 600) - 4) + 'px') // NOTE: xs(Extra small)の幅まで
    $('#footer').css('min-width', Math.floor(areaWidth) + 'px')
}
