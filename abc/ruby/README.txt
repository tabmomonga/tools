
=========================================================================
=  BASIC commands
=

mo-build  [SPECNAME  [...] ]

       build SPEC(s)


mo-install PKGFILE|CAPABILITY [...]

       build and install them



mo-upgrade [ PKGFILE|CAPABILITY   [...] ]

       upgrade or install packages

       if run without any PKGs or CAPABILITYs, this command will update
       every currently installed package.

       if one or more package or capabilities are specified, this command 
       will only update the required packages. 


mo-report-{upload,download,list}

       {upload,download,list} the build logs


mo-touch-spec SPECNAME [...]

        touth SPECNAME/SPECNAME.spec

============================================================================
= Querying commands
=

mo-{specdb,pkgdb}-{provides,requires}  {SPECNAME,PKGFILE}

       List all capabilities that {SPECNAME,PKGFILE} provides

mo-{specdb,pkgdb}-{whatprovides,whatrequires}   CAPABILITY [...]

       Query all {spec,pkg}s that {provide,require} the CAPABILITY

