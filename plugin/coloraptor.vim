inoremap <C-g>c <C-o>:call ColorPicker(0)<CR>
nnoremap cr :<C-u>call ColorPicker(1)<CR>

if prop_type_get('ColorPickerPreviewProp') != {}
	call prop_type_delete('ColorPickerPreviewProp')
endif
call prop_type_add('ColorPickerPreviewProp', #{ highlight: 'ColorPickerPreviewHighlight' })
hi ColorPickerPreviewHighlight guibg=#FF0099

let s:lastRunIsNormal = 1
let s:lastNormalRun_OriginalColor = ''
let s:lastNormalRun_CursorPos = -1

let g:ColorPickerCurrent = #{ r: 250, g: 0, b: 120 }
let s:current_slider = 'r'

let s:popup_lines = [
			\ #{ text: '' },
			\ #{ text: 'RGB Picker' },
			\ #{ text: '' },
			\ #{ text: '        ' . repeat(' ', 10), props: [#{ col: 9, length: 10, type: 'ColorPickerPreviewProp' }] },
			\ #{ text: '#000000 ' . repeat(' ', 10), props: [#{ col: 9, length: 10, type: 'ColorPickerPreviewProp' }] },
			\ #{ text: '        ' . repeat(' ', 10), props: [#{ col: 9, length: 10, type: 'ColorPickerPreviewProp' }] },
			\ #{ text: '' },
			\ #{ text: 'R' },
			\ #{ text: '' },
			\ #{ text: 'G' },
			\ #{ text: '' },
			\ #{ text: 'B' },
			\ #{ text: '' },
			\ ]

let s:n = 1
let s:lnums = {}
for line in s:popup_lines
	if line.text ==# 'R'
		let s:lnums.r = s:n
	elseif line.text ==# 'G'
		let s:lnums.g = s:n
	elseif line.text ==# 'B'
		let s:lnums.b = s:n
	elseif line.text =~# '^#'
		let s:lnums.c = s:n
	endif
	let s:n += 1
endfor
unlet s:n

function! ColorPicker(isNormal) abort
	let s:lastRunIsNormal = a:isNormal

	if a:isNormal
		let prev_isk = &iskeyword
		try
			let &iskeyword = 'a-f,0-9'
			let color_under_cursor = expand('<cword>')[:5]
		finally
			let &iskeyword = prev_isk
		endtry

		let g:ColorPickerCurrent.r = str2nr(color_under_cursor[0:1], 16)
		let g:ColorPickerCurrent.g = str2nr(color_under_cursor[2:3], 16)
		let g:ColorPickerCurrent.b = str2nr(color_under_cursor[4:5], 16)

		let s:lastNormalRun_OriginalColor = color_under_cursor
		let s:lastNormalRun_CursorPos = getcurpos()
	endif

	let options = { 'title': 'Color Picker', 'pos': 'center', 'drag': 1, 'resize': 1, 'close': 'button', 'padding': [1, 3, 1, 3], 'mapping': 0 }
	let options.filter = funcref('ColorPickerFilter')

	let window_id = popup_create(s:popup_lines, options)
	call ColorPickerRender(window_id)
endfunction

function! ColorPickerFilter(winId, key) abort
	if a:key ==# 'l'
		let g:ColorPickerCurrent[s:current_slider] += 1
		call ColorPickerRender(a:winId)
	elseif a:key ==# 'h'
		let g:ColorPickerCurrent[s:current_slider] -= 1
		call ColorPickerRender(a:winId)
	elseif a:key ==# 'w'
		let g:ColorPickerCurrent[s:current_slider] += 10
		call ColorPickerRender(a:winId)
	elseif a:key ==# 'b'
		let g:ColorPickerCurrent[s:current_slider] -= 10
		call ColorPickerRender(a:winId)
	elseif a:key ==# 'j'
		if s:current_slider ==# 'r'
			let s:current_slider = 'g'
		elseif s:current_slider ==# 'g'
			let s:current_slider = 'b'
		elseif s:current_slider ==# 'b'
			let s:current_slider = 'r'
		endif
		call ColorPickerRender(a:winId)
	elseif a:key ==# 'k'
		if s:current_slider ==# 'r'
			let s:current_slider = 'b'
		elseif s:current_slider ==# 'g'
			let s:current_slider = 'r'
		elseif s:current_slider ==# 'b'
			let s:current_slider = 'g'
		endif
		call ColorPickerRender(a:winId)
	elseif a:key ==# "\<Enter>"
		call popup_close(a:winId)
		let color = toupper(printf('%02x%02x%02x', g:ColorPickerCurrent.r, g:ColorPickerCurrent.g, g:ColorPickerCurrent.b))
		if s:lastRunIsNormal
			call execute('s,\V\%' . s:lastNormalRun_CursorPos[1] . 'l' . s:lastNormalRun_OriginalColor . ',' . color . ',')
			" FIXME: Slightly messes with the jumplist.
			call cursor(s:lastNormalRun_CursorPos[1:])
		else
			" Cursor position after inserting is not right.
			call execute('normal! i' . color)
		endif
	elseif a:key == "\<Esc>" || a:key == 'q'
		call popup_close(a:winId)
	endif
	return 1
endfunction

function! ColorPickerRender(winId) abort
	call win_execute(a:winId, s:SliderLineCommand('r', g:ColorPickerCurrent.r))
	call win_execute(a:winId, s:SliderLineCommand('g', g:ColorPickerCurrent.g))
	call win_execute(a:winId, s:SliderLineCommand('b', g:ColorPickerCurrent.b))
	let color = toupper(printf('%02x%02x%02x', g:ColorPickerCurrent.r, g:ColorPickerCurrent.g, g:ColorPickerCurrent.b))
	call execute('hi ColorPickerPreviewHighlight guibg=#' . color)
	call win_execute(a:winId, s:lnums.c . 'normal! lcw' . color)
endfunction

function! s:SliderLineCommand(name, value) abort
	return s:lnums[a:name] . 'normal! cc' . (s:current_slider ==# a:name ? '-> ' : '   ') . toupper(a:name) . ': '
				\ . printf('%3d', a:value) . ' ' . repeat('X', round(a:value * 50.0 / 256)->float2nr())
				\ . repeat('-', 50 - round(a:value * 50.0 / 256)->float2nr())
endfunction
