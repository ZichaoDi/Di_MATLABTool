/***************************************************************************
              util.h  -  Collection of various utility functions
                             -------------------
    begin                : Mon May 28 2001
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
 * Revision: $Rev: 3517 $
 *           $Date: 2013-03-26 19:26:43 +0100 (Di, 26. Mär 2013) $
 *           $Author: willkomm $
 *
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifndef ADM_CLIENT_UTIL_H
#define ADM_CLIENT_UTIL_H
#include "stringtable.h"

#define PATH_SEPARATOR_UNIX ':'
#define PATH_SEPARATOR_WINDOWS ';'

#if defined _WIN32 && !defined __CYGWIN__
 /* Use windows separators on all _WIN32 defining environments, except Cygwin. */
#define DIR_SEPARATOR '\\'
#define DIR_SEPARATOR_STR "\\"
#define DIR_SEPARATORS_STR "/\\"
#endif

#ifndef DIR_SEPARATOR
#define DIR_SEPARATOR '/'
#define DIR_SEPARATOR_STR "/"
#define DIR_SEPARATORS_STR "/"
#endif

#ifdef PATH_SEPARATOR
// FIXME: this is a temporary test to ensure clean migration (remove this ifdef)
#error that should not be defined
#endif

/** Some utility functions. Often used but not larger enough for a single file. */

/** check if path exists and is a directory. */
extern bool isDir(std::string const &path);

/** check if file exists. */
extern bool fileExists(std::string const &filename);

/** Checks, if in is a valid path, so if it terminates in a '/', if not the
   string is copied and a '/' is added and the new string is returned in out.
   out is null if the in-string was ok */
extern std::string ensurePath(std::string const &);

/** Ensures that the postfix is at the end of the filename.
   Behaviour like ensurePath. */
extern void ensurePostfix(char const *filename, const char *postfix, char **out);

/** Strip the postfix from the filename by inserting a nullbyte
   at the dot position. If the first character of the string is the only
   dot then it won't be stripped.
   !!! The string isn't coppied !!!*/
extern std::string stripPostfix(std::string const &in, std::string const &postifx);

/** Return the smallest of the two arguments. */
extern int min(int, int);

/** Replace the environmentvariables in the string orig with their values.
   orig is copied anyway and the new pointer is returned by the function.*/
std::string replaceEnvs(std::string const &original);

/** Check if the path supplied is absolute, by looking at the first char.
   On Unix-systems: The first char has to be a '/' to indicate an absolute path.
   On Win-system: The first char may be a '/', '\', of a char of [A-zA-Z] followed
      by a ':', to indicate an absolute path.
   Returns one if absolute, zero else.*/
extern bool isAbsolutePath(std::string const &path);

/** Strip the path of double DIR_SEPERATORS or /./ parts.
 * param  String with double slashes
 * returns Copy of string without double slashes and so on.*/
extern char* cleanupPath(const char *in);

/** Strips the filename from fileandpath and stores a copy of it in
   stripped_filename. If a path is in fileandpath, then it is copied
   and stored in stripped_path. If no path is present, then a copy of
   the empty string "" is returned in stripped_path. The stripped_path
   is beautified (i.e. env-vars are inserted).
 */
extern void stripPathfromString(std::string const &fileandpath, 
                                std::string &stripped_path, std::string &stripped_filename);

#endif






