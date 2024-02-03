import jquery from 'jquery'
window.$ = jquery

const debug = $("meta[name='debug']").attr('content') === 'true'

$(document).on('turbo:load', function(){
    if (debug) console.log('== turbo:load(switch_locale.js)')

    // 言語切り替え
    $('#switch_locale').on('change', function() {
        const value = $(this).val()
        if (debug) console.log('== #switch_locale.onchange', value)

        var url = new URL(window.location.href)
        url.searchParams.set('switch_locale', value)
        window.location.href = url
    })
})
