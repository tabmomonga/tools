
function abort(msg){
    printf "ABORT: %s\n", msg > "/dev/stderr"
    exit 1
}
function append_include(file,header)
{
    system(BIN"/append_include.sh "file" "header" gcc45~")
}
function insert_line(file,lineno,text)
{
    system(BIN"/insert_line.sh "file" "lineno" \""text"\"")
}


BEGIN{stackptr=-1
    "pwd"| getline  stack[++stackptr] 
    cur_dir = stack[stackptr]
}

# entering directory
$1~/^make.*:$/ && $2=="Entering" && $3=="directory" {
    stack[++stackptr] = substr($4,2,length($4)-2)
    # update cur_dir
    cur_dir = stack[stackptr]
}
# leaving directory
$1~/^make.*:$/ && $2=="Leaving" && $3=="directory" {
    # check
    if (stack[stackptr] != substr($4,2,length($4)-2)) { 
	abort("parse error " stack[stackptr] " " $4)
    } 
    # remove stack top
    stack[stackptr]=""
    --stackptr;
    # update cur_dir
    cur_dir = stack[stackptr]
}

function makesrcfile(cur,file)
{
    if ( file~/^\// ) {
	return file
    } else {
	return sprintf("%s/%s", cur, file)
    }
}

# ERROR: ??? was not declared in this scope
# JOB:   add "#include <???>"
$2=="error:" && ( $0~/was not declared in this scope$/ || $0~/has not been declared$/ || $0~/'.+' undeclared / ) {
    split($1,file,":")
    srcfile=makesrcfile(cur_dir, file[1])

    ##print srcfile, "***" , $0

    funcname=substr($3,2,length($3)-2)

    # canonical synbol name
    sub(/^::/,"",funcname)
    sub(/^std::/,"",funcname)
    
    cmd=BIN"/guess_required_header.sh "funcname
    while ((cmd|getline filename)>0) {
	append_include(srcfile,filename)
    }
    close(cmd)
}

# ERROR: iclude <typeinfo> before using typeid
# JOB: #include <typeinfo>
$2=="error:" && $0~/typeinfo> before using typeid$/ {
    split($1,file,":")
    srcfile=makesrcfile(cur_dir, file[1])

    append_include(srcfile,"typeinfo")
}

# ERROR: ISO C++ forbids declaration of 'auto_ptr' with no type
# JOB:   add "#include <memory>"
$2=="error:" && $0~/ISO C\+\+ forbids declaration of 'auto_ptr' with no type$/ {
    split($1,file,":")
    srcfile=makesrcfile(cur_dir, file[1])

    append_include(srcfile,"memory")
}

# ERROR: "???" redefined
# JOB:   #undef "???"
$2=="error:" && $0~/redefined$/ {
    split($1,file,":")
    srcfile=makesrcfile(cur_dir, file[1])
    lineno=file[2]
    label=substr($3,2,length($3)-2)
    insert_line(srcfile,lineno,"#undef "label)
}

# ERROR: ??? is not a member of 'std'
# JOB:   #include  <???>
$2=="error:" && $0~/is not a member of 'std'$/ {
    split($1,file,":")
    srcfile=makesrcfile(cur_dir, file[1])

    funcname=substr($3,2,length($3)-2)

    # canonical synbol name
    sub(/^::/,"",funcname)
    sub(/^std::/,"",funcname)

    cmd=BIN"/guess_required_header.sh "funcname
    while ((cmd|getline filename)>0) {

	# use std namespace
	if (1==sub(/\.h$/,"",filename)) {
	    filename="c"filename
	}

	append_include(srcfile,filename)
    }
    close(cmd)
}

# ERROR:  no matching function for call to 'find ...
$2=="error:" && $0~/no matching function for call to/ {
    split($1,file,":")
    srcfile=makesrcfile(cur_dir, file[1])

    split($9,token,"(")
    funcname=substr(token[1],2,length(token[1])-1)
    
    if (funcname=="sort" ||
	funcname=="transform" ||
	funcname=="find" ||
	funcname=="find_if") {
	    append_include(srcfile,"algorithm")
    }
}

