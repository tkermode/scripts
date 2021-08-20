jhead -ft -n%Y%m%d-%H%M%S *.jpg
jhead -ft -n%Y%m%d-%H%M%S *.JPG
exiftool  -d "%Y%m%d-%H%M%S" "-filename<createdate" *.MOV
