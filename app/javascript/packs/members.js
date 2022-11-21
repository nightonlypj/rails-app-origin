const debug = $("meta[name='debug']").attr('content') === 'true'

$(document).on('turbolinks:load', function(){
    $('.dblclick_to_link').on('dblclick', function(event) {
        const href = $(this).attr('href')
        if (debug) console.log('== .dblclick_to_link.dblclick', href, event.target.innerHTML)

        if (event.target.innerHTML === '' || event.target.innerHTML.match(/type="checkbox"/)) {
            if (debug) console.log('...Skip')
            return
        }

        location.href = href
    })
})
