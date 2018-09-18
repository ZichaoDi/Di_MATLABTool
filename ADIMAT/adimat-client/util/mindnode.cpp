/***************************************************************************
                          mindnode.cpp  -  description
                             -------------------
    begin                : Mon May 14 2001
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
 * $Log: mindnode.cpp,v $
 * Revision 1.4  2003/07/03 13:52:22  af116ve
 * Removed bugs, that lead to memory leaks or crashes. (Valgrind!)
 *
 * Revision 1.3  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */

#include <typeinfo>
#include "mindnode.h"
#include "loggingstream.h"

/** Constructor for a mindnode */
mindnode::mindnode() : n_next(0), n_prev(0), mylist(0) {
#ifdef DEBUG
  logger(ls::TALKATIVE) << "Create mindnode " << (void*) this << "\n";
#endif
}

/** Copy constructor for a mindnode */
mindnode::mindnode(mindnode const &o) : 
  n_next(o.n_next), 
  n_prev(o.n_prev), 
  mylist(o.mylist) {
#ifdef DEBUG
  logger(ls::TALKATIVE) << "Create copy of mindnode " << (void*) this << "\n";
#endif
}

/** Destructor, remove myself from the list only when I'm still on it. */
mindnode::~mindnode() {
#ifdef DEBUG
  logger(ls::TALKATIVE) << "Delete mindnode " << (void*) this << "\n";
#endif
   if (mylist) {
      mylist->remove(this);
      mylist = 0;
   }
   clearPtrs();
}

/** Duplicate the information of this node. */
mindnode * mindnode::duplicate() const {
   return new mindnode();
}

void mindnode::writeXML(std::ostream& out, std::string const &indent) {
  out << indent << "<unknown-graph-node c-type='" << typeid(*this).name() << "'/>\n";
}

void mindnode::clearPtrs() {
   n_next = n_prev = 0;
}
