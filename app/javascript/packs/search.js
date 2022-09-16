const debug = $("meta[name='debug']").attr('content') === 'true'

$(document).on('turbolinks:load', function(){
    // 検索オプションクリック -> 追加項目開閉
    $('#option_btn').on('click', function() {
        const expanded = $('#option_btn').attr('aria-expanded') === 'true'
        if (debug) console.log('== #option_btn.onclick', expanded, $("#option").val())

        $('#option').val(expanded ? 1 : '')
        $('#option_open').css('display', expanded ? 'none' : 'block')
        $('#option_close').css('display', expanded ? 'block' : 'none')
    })

    // 入力・クリック -> 検索ボタン有効化
    $('.input_to_search_btn_enabled').on('input', function() {
        if (debug) console.log('== .input_to_search_btn_enabled.oninput')

        $('#search_btn').prop('disabled', false)
    })
    $('.click_to_search_btn_enabled').on('click', function() {
        if (debug) console.log('== .click_to_search_btn_enabled.onclick')

        $('#search_btn').prop('disabled', false)
    })
})
