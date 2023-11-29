import jquery from 'jquery'
window.$ = jquery

const debug = $("meta[name='debug']").attr('content') === 'true'
let leftMenuDisplay = null

$(document).on('turbo:load', function(){
    if (debug) console.log('== turbo:load', leftMenuDisplay)

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
