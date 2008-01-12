
function abort(msg){
    printf "ABORT: %s\n", msg
    exit 1
}
function append_include(file,header)
{
    system(BIN"/append_include.sh "file" "header" gcc43~")
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
