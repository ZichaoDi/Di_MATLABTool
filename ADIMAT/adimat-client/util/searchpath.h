/*** -*- C++ -*- ***********************************************************
                          searchpath.h  -  description
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
 * $Log: searchpath.h,v $
 * Revision 1.6  2002/06/14 17:50:36  af116ve
 * Stringtable is now a singleton. Patched file to respect this.
 *
 * Revision 1.5  2002/05/13 13:27:33  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#ifndef SEARCHPATH_H
#define SEARCHPATH_H

#include <mindlist.h>
#include "stringtable.h"

#define BUILTINTAG 1

/**Hosts the searchpath. The path where to look for functionfiles.
  *@author Andre Vehreschild
  */


class SearchPath : public mindlist  {
public:
	/** Create the SearchPath- class. It's empty now. */
	SearchPath();
	/** Free all path items. */
	~SearchPath();
	/** Add one item to the search path. The contents of one is copied. */
	void add(std::string const &one);
	/** Looks into the path and tries to find a file, that matches the id. */
        inline std::string lookup(StringTable::id id) {
		return lookup(StringTable::get()->index(id));
	};
	/** Looks into the path and tries to find a file, that matches the name. */
	std::string lookup(std::string const &name, std::string const &postfix= ".m");
	/** Add one or more entries to the searchpath by scanning the string for seperating ':'.
		Return false, when an error occured and true else.*/
	bool multiAdd(char const *mult);
private:
	/** Set the following flag, if the @BUILTINS- item is used. This flag prevents double use
		of this feature. */
	bool builtinsused;
};

#endif
