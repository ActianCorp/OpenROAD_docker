# Actian X environment for OR installation

TERM_INGRES=konsolel

II_SYSTEM=/IngresOR
export II_SYSTEM

PATH=$II_SYSTEM/ingres/bin:$II_SYSTEM/ingres/utility:$PATH

if [ ${LD_LIBRARY_PATH:-} ] ; then
    LD_LIBRARY_PATH=$II_SYSTEM/ingres/lib:$II_SYSTEM/ingres/lib/lp32:$LD_LIBRARY_PATH
else
    LD_LIBRARY_PATH=/lib:/usr/lib:$II_SYSTEM/ingres/lib:$II_SYSTEM/ingres/lib/lp32
fi

export TERM_INGRES PATH LD_LIBRARY_PATH
