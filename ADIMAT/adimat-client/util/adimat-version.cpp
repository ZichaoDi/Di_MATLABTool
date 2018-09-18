/***************************************************************************
                          mach_env.cpp  -  description
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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <cstring>
#include <cstdlib>
#include <cerrno>
#include <climits>
#include <cstdlib>
#include <dirent.h>

#include "adimat-version.h"
#include "long-version.h"

const char *adimat_getLongVersionString() {
  return PACKAGE_NAME " " ADIMAT_LONG_VERSION;
}

/** Get the version string of ADiMat. */
const char *adimat_getPackageString() {
   return PACKAGE_STRING;
}

const char *adimat_getLongVersion() {
   return ADIMAT_LONG_VERSION;
}

const char *adimat_getVersion() {
   return VERSION;
}

double adimat_getVersionNumber() {
   return ADIMAT_VERSION_NUMBER;
}

