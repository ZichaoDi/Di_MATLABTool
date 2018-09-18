/***************************************************************************
                          item_searchpath.cpp  -  description
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
 * $Log: item_searchpath.cpp,v $
 * Revision 1.5  2003/07/25 12:25:02  af116ve
 * Better support for system-indepented builts.
 *
 * Revision 1.4  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <cstring>
#include <cstdlib>

#include "item_searchpath.h"
#include "loggingstream.h"

/** Create one new entry with the contents contnt. Duplicating the string. */
item_SearchPath::item_SearchPath(std::string const &contnt) :
  mindnode::mindnode(),
  content(contnt),
  tag()
{
#ifdef DEBUG
   logger(ls::TALKATIVE)<< "Added '"<< content << "' to the searchpath.\n";
#endif
}

/** Creating an entry using this constructor, wil store it as a special tag.
Fetching the string of the special tag wil result in an error. */
item_SearchPath::item_SearchPath(int t): 
  tag(t)
{}

/** Destruct the entry. */
item_SearchPath::~item_SearchPath() {}

/** Get the content of this node -> the path. */
std::string const &item_SearchPath::getPath() const {
  if(content.empty()) {
    logger(ls::ERROR)<< "Requesting string-information of a tag-item_SearchPath-object. Returning empty string!!!\n";
  }
  return content;
}

/** Return the tag-value of this item. Zero if the tag isn't set.
It is safe to first test for the tag-value and then if it was zero
getting the string. */
int item_SearchPath::getTag() const {
   return tag;
}

/** Compare the current item with the string compwith. Return true if equal. */
bool item_SearchPath::operator==(std::string const &compwith) const {
  if (not content.empty())
    return content.compare(compwith) == 0;
  else
    return false;
}
