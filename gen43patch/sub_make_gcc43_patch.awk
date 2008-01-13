
function abort(msg){
    printf "ABORT: %s\n", msg
    exit 1
}
function append_include(file,header)
{
    system(BIN"/append_include.sh "file" "header" gcc43~")
}
function insert_line(file,lineno,text)
{
    system(BIN"/insert_line.sh "file" "lineno" \""text"\"")
}

BEGIN{"pwd"| getline cur_dir}
# entering directory
$1~/^make.*:$/ && $2="Entering" && $3="directory" {
    cur_dir=substr($4,2,length($4)-2)
}
# leaving directory
$1~/^make.*:$/ && $2="Leaving" && $3="directory" {
    if (cur_dir!=substr($4,2,length($4)-2)) { 
	abort("parse error")
    } 
}



# ERROR: ??? was not declared in this scope
# JOB:   add "#include <???>"
$2=="error:" && $0~/was not declared in this scope$/ {
    split($1,file,":")
    srcfile=sprintf("%s/%s", cur_dir, file[1])

    ##print srcfile, "***" , $0

    funcname=substr($3,2,length($3)-2)
    
    cmd=BIN"/guess_required_header.sh "funcname
    while ((cmd|getline filename)>0) {
	append_include(srcfile,filename)
    }
    close(cmd)
}

# error: 'find_if' was not declared in this scope
# JOB:   add "#include <algorithm>"
$2=="error:" && $0~/'find_if' was not declared in this scope$/ {
    split($1,file,":")
    srcfile=sprintf("%s/%s", cur_dir, file[1])

    append_include(srcfile,"algorithm")
}

# ERROR: iclude <typeinfo> before using typeid
# JOB: #include <typeinfo>
$2=="error:" && $0~/typeinfo> before using typeid$/ {
    split($1,file,":")
    srcfile=sprintf("%s/%s", cur_dir, file[1])

    append_include(srcfile,"typeinfo")
}

# ERROR: ISO C++ forbids declaration of 'auto_ptr' with no type
# JOB:   add "#include <memory>"
$2=="error:" && $0~/ISO C\+\+ forbids declaration of 'auto_ptr' with no type$/ {
    split($1,file,":")
    srcfile=sprintf("%s/%s", cur_dir, file[1])

    append_include(srcfile,"memory")
}

# ERROR: "???" redefined
# JOB:   #undef "???"
$2=="error:" && $0~/redefined$/ {
    split($1,file,":")
    srcfile=sprintf("%s/%s", cur_dir, file[1])
    lineno=file[2]
    label=substr($3,2,length($3)-2)
    insert_line(srcfile,lineno,"#undef "label)
}