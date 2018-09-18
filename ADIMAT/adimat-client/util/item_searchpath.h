/**** -*- C++ -*- **********************************************************
                          item_searchpath.h  -  description
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
 * $Log: item_searchpath.h,v $
 * Revision 1.4  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#ifndef ITEM_SEARCHPATH_H
#define ITEM_SEARCHPATH_H

#include <mindnode.h>

/**One entry of the search path.
  *@author Andre Vehreschild
  */

class item_SearchPath : public mindnode  {
public:
	/** Create one new entry with the contents contnt. Duplicating the string. */
	item_SearchPath(std::string const &contnt);
	/** Get the content of this node -> the path. */
	std::string const &getPath() const;
	/** Destruct the entry, freeing it's memory. */
	virtual ~item_SearchPath();
	/** Creating an entry using this constructor, wil store it as a special tag.
		Fetching the string of the special tag wil result in an error. */
	item_SearchPath(int tag);
	/** Return the tag-value of this item. Zero if the tag isn't set.
		It is safe to first test for the tag-value and then if it was zero
		getting the string. */
	int getTag() const;
  /** Compare the current item with the string compwith. Return true if equal. */
  bool operator==(std::string const &compwith) const;
private: // Private attributes
	/** The name of the path. */
	std::string const content;
	/** The tag value if used, else zero. */
	int tag;
};

#endif
