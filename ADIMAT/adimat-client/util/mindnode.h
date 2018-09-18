/***************************************************************************
                          mindnode.h  -  description
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
 * $Log: mindnode.h,v $
 * Revision 1.6  2003/09/18 14:42:23  af116ve
 * Beautification.
 * Added insertafter-method.
 *
 * Revision 1.5  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#ifndef MINDNODE_H
#define MINDNODE_H

#include <iostream>
#include "mindlist.h"

/** The node-class. */
class mindnode {
   friend class mindlist;
public:
   /** Create an empty node. All members are zeroed. */
   mindnode();
   /** Copy a node. All members are copied. */
   mindnode(mindnode const &);
   /** Destroy the node. */
   virtual ~mindnode();
   /** Return the n_prev-node preceding this one. NULL if first node. */
   inline mindnode* prev_node() const {return n_prev;};
   /** Return the n_next-node following this one. NULL if last node. */
   inline mindnode* next_node() const {return n_next;};
   /** Return the list I'm in. */
   inline mindlist* getList() const {return mylist;};
   /** Duplicate the information of this node. */
   virtual mindnode * duplicate() const;
   /** Insert ins before this node in this nodes list. */
   inline void insertbefore(mindnode *ins) {mylist->insertbefore(ins, this);};
   /** Insert list ins before this node in this nodes list. */
   inline void insertbefore(mindlist *ins) {mylist->insertbefore(ins, this);};
   /** Insert this node into this nodes list after this one. */
   inline void insertafter(mindnode *nn) {mylist->insertafter(nn, this);};
   /** Insert list ins after this node in this nodes list. */
   inline void insertafter(mindlist *ins) {mylist->insertafter(ins, this);};
  // FIXME: make this function const
   virtual void writeXML(std::ostream& out, std::string const &indent = "");
   void clearPtrs();
private:
   /** The next and previous list nodes. NULL if nonexistent.*/
   mindnode *n_next, *n_prev;
   /** The list this node is in. */
   mindlist *mylist;
};

// Local Variables:
// mode: C++;
// End:
#endif
