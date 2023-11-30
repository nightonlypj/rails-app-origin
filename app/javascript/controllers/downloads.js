import jquery from 'jquery'
window.$ = jquery

const debug = $("meta[name='debug']").attr('content') === 'true'

$(document).on('turbo:load', function(){
    $('.click_to_sleep_reload').on('click', function() {
        if (debug) console.log('== .click_to_sleep_reload.onclick')

        setTimeout(function(){
            if (debug) console.log('reload')
            location.reload()
        }, 100)
    })
})
