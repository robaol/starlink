/* 
 * tkAppInit.c --
 *
 *	Provides a default version of the Tcl_AppInit procedure for
 *	use in wish and similar Tk-based applications.
 *
 * Copyright (c) 1993 The Regents of the University of California.
 * Copyright (c) 1994 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tkAppInit.c 1.22 96/05/29 09:47:08
 */

#include "tk.h"
#include "itk.h"
#include "tclAdam.h"
#include "tkGwm.h"
/* #include "blt.h" */

/* include tclInt.h for access to namespace API */
#include "tclInt.h"

/*
 * The following variable is a special hack that is needed in order for
 * Sun shared libraries to be used for Tcl.
 */

extern int matherr();
int *tclDummyMathPtr = (int *) matherr;

#ifdef TK_TEST
EXTERN int		Tktest_Init _ANSI_ARGS_((Tcl_Interp *interp));
#endif /* TK_TEST */

/*
 *----------------------------------------------------------------------
 * Declare functions defining new Tcl commands which we will define in
 * Tcl_AppInit.  Doing this ensures that they have the correct 
 * declaration where defined.
 *----------------------------------------------------------------------
 */

Tcl_ObjCmdProc tclbgcmd;
Tcl_ObjCmdProc NdfDrawpair;
Tcl_ObjCmdProc NdfCentroffset;
Tcl_ObjCmdProc CcdputsCmd;
Tcl_ObjCmdProc IntersectCmd;


/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit --
 *
 *	This procedure performs application-specific initialization.
 *	Most applications, especially those that incorporate additional
 *	packages, will have their own version of this procedure.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error
 *	message in interp->result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_AppInit(interp)
    Tcl_Interp *interp;		/* Interpreter for application. */
{
    if (Tcl_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    if (Tk_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Tk", Tk_Init, Tk_SafeInit);
#ifdef TK_TEST
    if (Tktest_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Tktest", Tktest_Init,
            (Tcl_PackageInitProc *) NULL);
#endif /* TK_TEST */


    /*
     * Call the init procedures for included packages.  Each call should
     * look like this:
     *
     * if (Mod_Init(interp) == TCL_ERROR) {
     *     return TCL_ERROR;
     * }
     *
     * where "Mod" is the name of the module.
     */
    if (Itcl_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    if (Itk_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    if (Tcladam_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
/*
    if (Blt_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
*/
    if (Tkgwm_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    if (Ndf_Init(interp) == TCL_ERROR) {
        return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Itcl", Itcl_Init, Itcl_SafeInit);
    Tcl_StaticPackage(interp, "Itk", Itk_Init, (Tcl_PackageInitProc *) NULL);
    Tcl_StaticPackage(interp, "Tcladam", Tcladam_Init, (Tcl_PackageInitProc *) NULL);
/*
    Tcl_StaticPackage(interp, "Blt", Blt_Init, (Tcl_PackageInitProc *) NULL);
*/

/* This is a temporary measure until I can get BLT working. */
    if (Tcl_Eval( interp, "namespace eval blt { proc busy { args } { } }" )
          == TCL_ERROR) {
       return TCL_ERROR;
    }

    Tcl_StaticPackage(interp, "Tkgwm", Tkgwm_Init, (Tcl_PackageInitProc *) NULL);
    Tcl_StaticPackage(interp, "Ndf", Ndf_Init, (Tcl_PackageInitProc *) NULL);

    /*
     *  This is itkwish, so import all [incr Tcl] commands by
     *  default into the global namespace.  Fix up the autoloader
     *  to do the same.
     */
    if (Tcl_Import(interp, Tcl_GetGlobalNamespace(interp),
            "::itk::*", /* allowOverwrite */ 1) != TCL_OK) {
        return TCL_ERROR;
    }

    if (Tcl_Import(interp, Tcl_GetGlobalNamespace(interp),
            "::itcl::*", /* allowOverwrite */ 1) != TCL_OK) {
        return TCL_ERROR;
    }
    /*
    if (Tcl_Eval(interp, "auto_mkindex_parser::slavehook { _%@namespace import -force ::itcl::* ::itk::* }") != TCL_OK) {
        return TCL_ERROR;
    }
    */
    if (Tcl_Eval(interp, "auto_mkindex_parser::slavehook { _%@namespace import -force ::itcl::class }") != TCL_OK) {
        return TCL_ERROR;
    }

    /*
     * Call Tcl_CreateCommand for application-specific commands, if
     * they weren't already created by the init procedures called above.
     *
     * Note that commands which could block for a significant amount of
     * time are declared via the tclbgcmd mechanism.
     */

    Tcl_CreateObjCommand( interp, "ndfdrawpair", NdfDrawpair,
                          (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL );
    Tcl_CreateObjCommand( interp, "ndfcentroffset", NdfCentroffset,
                          (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL );
    Tcl_CreateObjCommand( interp, "ccdputs", CcdputsCmd,
                          (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL );
    Tcl_CreateObjCommand( interp, "intersect", IntersectCmd,
                          (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL );

    /*
     * Specify a user-specific startup file to invoke if the application
     * is run interactively.  Typically the startup file is "~/.apprc"
     * where "app" is the name of the application.  If this line is deleted
     * then no user-specific startup file will be run under any conditions.
     */

    Tcl_SetVar(interp, "tcl_rcFileName", ".ccdwishrc", TCL_GLOBAL_ONLY);
    return TCL_OK;
}
