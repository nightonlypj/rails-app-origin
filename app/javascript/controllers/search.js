import jquery from 'jquery'
window.$ = jquery

const debug = $("meta[name='debug']").attr('content') === 'true'
let checked = 0

$(document).on('turbo:load', function(){
    // 検索オプション -> 追加項目開閉
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

    // チェックボックス -> 削除ボタン有効・無効化、選択件数表示
    $('.change_to_delete_btn_enabled').on('change', function() {
        const check = $(this).prop('checked')
        if (debug) console.log('== .change_to_delete_btn_enabled.onchange', checked, check)

        if (check) {
            checked += 1
        } else {
            checked -= 1
        }
        $('#delete_btn').prop('disabled', checked <= 0)
    })

    // ダウンロードボタン -> URLにコードを追加して遷移
    $('.click_to_redirect_add_codes').on('click', function() {
        const href = $(this).prop('href')
        if (debug) console.log('== .click_to_redirect_add_codes.onclick', href)

        let codes = []
        const elements = $('input[id^="codes["]')
        for (var element of elements) {
            if (element.checked) codes.push(element.id.substr(6, (element.id + ']').indexOf(']') - 6))
        }

        let url = new URL(href)
        url.searchParams.append('select_items', codes)
	    location.href = url
        return false
    })
})
