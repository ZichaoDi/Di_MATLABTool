/***************************************************************************
                          mach_env.h  -  description
                             -------------------
    begin                : Tue May 22 2001
    copyright            : (C) 2001 by Andre Vehreschild
    email                : vehreschild@sc.rwth-aachen.de
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   * 
 *                                                                         *
 ***************************************************************************/
/*
 * $Log: mach_env.h,v $
 * Revision 1.11  2003/12/05 17:49:56  af116ve
 * Added command-line flags to specify the (in-)dependent variables on the command-line.
 *
 * Revision 1.10  2003/04/15 10:30:57  af116ve
 * Added support for second-order derivative computation including a new global variable which stores prefix of the hessian.
 *
 * Revision 1.9  2002/09/24 20:18:05  af116ve
 * Cosmetics.
 *
 * Revision 1.8  2002/06/14 17:50:36  af116ve
 * Stringtable is now a singleton. Patched file to respect this.
 *
 * Revision 1.7  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */

#ifndef MACH_ENV_H
#define MACH_ENV_H

#include "searchpath.h"

/** The name of the environment variable ADIMAT_HOME */
extern const char *ENV_HOME;

/** The name of the environment variable ADIMAT_BUILTINS */
extern const char *ENV_BUILTINS;

/** The name this program is called with. */
extern char * adimatname;

/** The path to add to differentiated files. */
extern StringTable::id outputpathid;

/** The file name to write differentiated files to. */
extern StringTable::id outputfileid;

/** The path where the root of ADIMAT should be installed. */
extern char const * adimathome;

/** The builtin filename, which is looked up in the builtinspath. */
extern char const * builtinsfilename;

/** The path to scan for the builtins-file. */
extern char const * builtinspath;

/** The path to database file containing the builtin-definitions. */
extern char const * builtinsdbfilename;

/** If the user want's the calltree written than this has the filenameid,
	else it is 0. (The postfix is allready added!)*/
extern StringTable::id cgvcgname;

/** If the user wants the calltree to be written in a simple file, then
	do it by using this name. No postfix is ensured. */
extern StringTable::id cgsimpname;

/** If the user wants the calltree to be written in a human readable file,
	then do it by using this name. No postfix is ensured. */
extern StringTable::id cgtxtname;

/** If the user want's the dependencygraph written than this has the filenameid,
	else it is 0. (The postfix is allready added!)*/
extern StringTable::id dgvcgname;

/** If the user wants parsed AST to be written in a XML file,
    then do it by using this name. No postfix is ensured. */
extern StringTable::id xmlDumpFileName;
extern StringTable::id xmlDependenciesFileName;
extern StringTable::id dependenciesListFileName;
extern StringTable::id xmlUnboundFileName;
extern StringTable::id xmlFunctionListFileName;

/** Set the input encoding of the file. This is necessary because the
 XML processor needs to now if that is not "us-ascii", which is the
 default */
extern StringTable::id inputEncodingName;

/** The prefix a gradient variable gets. */
extern StringTable::id gradvarprefixid;

/** The prefix a gradient variable gets. */
extern StringTable::id hessvarprefixid;

/** Id of the prefix of function-names. (default: 'ad_') */
extern StringTable::id funcprefixid;

/** The complexity-border where subexpressions are canonicalized. */
extern int canonicalize_complexity;

/** The list of dependent variables specified at the command-line.
 * A comma seperated char array. */
extern char const *parm_dependents;

/** The list of independent variables specified at the command-line.
 * A comma seperated char array. */
extern char const *parm_independents;

extern char const * adimatXMLNamespaceURI;

/** Get the version string of ADiMat. */
extern const char *adimat_getVersion();

extern const char *adimat_getLongVersionString();

extern const char *adimat_getLongVersion();

extern const char *adimat_getFeatures();

/** Get the HOST_ARCH string of ADiMat. */
const char *adimat_getHostArch();

/** Get the build date string of ADiMat. */
const char *adimat_getBuildDate();

/** Print the version-line of Adimat. */
extern void adimat_printVersion();

/** Look for environment variables of the calling shell. Like the path
	to the ADIMAT-configurationfiles. */
extern void scanMachineenvironment();

/** Look for all known parameters, prompt unknown and change intern data
	to get the requested state. Terminates programm on error.
	In mfilename the mandatory argument of the file to work on is returned.*/
extern void parseParameters(int argc, char **argv, std::string &mfilename, SearchPath *p);

#endif
