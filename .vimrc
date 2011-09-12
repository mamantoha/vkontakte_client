set runtimepath+=/home/user/snippetsemu
set runtimepath+=/home/user/snippetsemu/after

" Несумісність настройок з Vi  
set nocompatible  
" Включити підсвітку синтаксису  
syntax on  
filetype on  
filetype indent on  
filetype plugin on  

" Завжди показувати положення курсору.
set ruler  

" Ukrainian support | CTRL+^
set keymap=ukrainian-jcuken 
" by default - latin keymap 
set iminsert=0  
" by default - latin keymap for search
set imsearch=0  

set fileencodings=utf-8,cp1251,cp866,koi8-u
set encoding=utf-8  
set termencoding=utf-8  

" Формат строки стану
set statusline=%t\ %y%m%r[%{&fileencoding}][%{&spelllang}][%{&fileformat}]%<[%{strftime(\"%d.%m.%y\",getftime(expand(\"%:p\")))}]%k%=%-14.(%l,%c%V%)\ %P 
set laststatus=2  
colorscheme desert  

" Підтримка мишки
"set mouse=a  
"set mousemodel=popup

" Ховати вказівник миші під час друку.
set mousehide  

" Розмір табуляції по замовчуванню
set tabstop=2  
set softtabstop=2  
set shiftwidth=2  
" Перетворення Таба в пробіли  
set expandtab  


" Включити "розумні" відступи ( наприклад, авто відступи після {)
set smartindent  
set hlsearch  

" Включити нумерацію рядків
set number  

" Пробіл в нормальному режимі перелистує сторінки
nmap <Space> <PageDown>  

" F2 - швидке зберігання
nmap <F2> :w<cr>  
vmap <F2> <esc>:w<cr>i  
imap <F2> <esc>:w<cr>i  

" <F7> File fileformat (dos - <CR> <NL>, Unix - <NL>, mac - <CR>)
map <F7> :execute RotateFileFormat()<CR>  
vmap <F7> <C-C><F7>  
imap <F7> <C-O><F7>  
let b:fformatindex=0  

function! RotateFileFormat()
  let y = -1  
  while y == -1  
    let encstring = "#unix#dos#mac#"
    let x = match(encstring,"#",b:fformatindex)
    let y = match(encstring,"#",x+1)  
    let b:fformatindex = x+1  
    if y == -1  
      let b:fformatindex = 0  
    else  
      let str = strpart(encstring,x+1,y-x-1)  
      return ":set fileformat=".str  
    endif  
  endwhile  
endfunction  

" <F8> File encoding for open
" ucs-2le - MS Windows Unicode encoding
map <F8> :execute RotateEnc()<CR>  
vmap <F8> <C-C><F8>  
imap <F8> <C-O><F8>  
let b:encindex=0  
function! RotateEnc()  
  let y = -1  
  while y == -1  
    let encstring = "#koi8-r#cp1251#8bit-cp866#utf-8#ucs-2le#"
    let x = match(encstring,"#",b:encindex)  
    let y = match(encstring,"#",x+1)  
    let b:encindex = x+1  
    if y == -1  
      let b:encindex = 0  
    else  
      let str = strpart(encstring,x+1,y-x-1)  
      return ":e ++enc=".str  
    endif  
  endwhile  
endfunction  

" <Shift+F8> Force file encoding for open (encoding = fileencoding)
map <S-F8> :execute ForceRotateEnc()<CR>  
vmap <S-F8> <C-C><S-F8>  
imap <S-F8> <C-O><S-F8>  
let b:encindex=0  
function! ForceRotateEnc()  
  let y = -1  
  while y == -1  
    let encstring = "#koi8-r#cp1251#8bit-cp866#utf-8#ucs-2le#"  
    let x = match(encstring,"#",b:encindex)  
    let y = match(encstring,"#",x+1)  
    let b:encindex = x+1  
    if y == -1  
      let b:encindex = 0  
    else  
      let str = strpart(encstring,x+1,y-x-1)  
      :execute "set encoding=".str  
      return ":e ++enc=".str  
    endif  
  endwhile  
endfunction  

" <Ctrl+F8> File encoding for save (convert)
map <C-F8> :execute RotateFEnc()<CR>  
vmap <C-F8> <C-C><C-F8>  
imap <C-F8> <C-O><C-F8>  
let b:fencindex=0
function! RotateFEnc()
  let y = -1
  while y == -1
    let encstring = "#koi8-r#cp1251#8bit-cp866#utf-8#ucs-2le#"
    let x = match(encstring,"#",b:fencindex)
    let y = match(encstring,"#",x+1)
    let b:fencindex = x+1
    if y == -1
      let b:fencindex = 0
    else
      let str = strpart(encstring,x+1,y-x-1)
      return ":set fenc=".str
    endif
  endwhile
endfunction

" F9 - зміна кодування файлу
set wildmenu
set wcm=<Tab>
menu Encoding.koi8-u :e ++enc=koi8-u<CR>
menu Encoding.windows-1251 :e ++enc=cp1251<CR>
menu Encoding.ibm-866 :e ++enc=ibm866<CR>
menu Encoding.utf-8 :e ++enc=utf-8 <CR>
map <F9> :emenu Encoding.<TAB>


" ftp://ftp.vim.org/pub/vim/runtime/spell/
if version >= 700
" По замовчуванню перевірка орфографії виключена.
  setlocal spell spelllang=
  setlocal nospell
  function ChangeSpellLang()
    if &spelllang == "en_us"
      setlocal spell spelllang=ru
    elseif &spelllang == "ru"
      setlocal spell spelllang=uk
    elseif &spelllang == "uk"
      setlocal spell spelllang=
      setlocal nospell
    else
      setlocal spell spelllang=en_us
    endif
  endfunc
  " map spell on/off
  map <F11> <Esc>:call ChangeSpellLang()<CR>
endif
