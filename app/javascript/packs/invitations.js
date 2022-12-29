const debug = $("meta[name='debug']").attr('content') === 'true'

$(document).on('turbolinks:load', function(){
    $('.dblclick_to_link').on('dblclick', function(event) {
        const href = $(this).attr('href')
        if (debug) console.log('== .dblclick_to_link.dblclick', href, event.target.innerHTML)

        location.href = href
    })

    $('.click_to_copy_clipboard').on('click', function(event) {
        const text = $(this).attr('text')
        if (debug) console.log('== .click_to_copy_clipboard.click', text, event.target.innerHTML)

        navigator.clipboard.writeText(text)
        .then(() => {
            alert($("meta[name='message']").attr('content'))
        }, () => {
            alert('failed.')
        })
    })
})
