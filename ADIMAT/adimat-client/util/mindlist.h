/***************************************************************************
                          mindlist.h  -  description
                             -------------------
    begin                : Fri May 4 2001
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
 * $Log: mindlist.h,v $
 * Revision 1.12  2004/05/12 14:33:52  af116ve
 * Cosmetics.
 * Constructors use initialisation instead of assignment now.
 * count is an inline method.
 *
 * Revision 1.11  2003/09/18 14:41:45  af116ve
 * Redesined interface of insert/append-method to more conveniert style.
 *
 * Revision 1.10  2003/07/25 12:23:57  af116ve
 * The type of the function passed to the map-method is now defined.
 * This enables easier casting of function objects.
 *
 * Revision 1.9  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */

#ifndef MINDLIST_H
#define MINDLIST_H

/* Forward declaration of mindnode. */
class mindnode;

/**A simple compact and minimal double linked list, with a counter.
  *@author Andre Vehreschild
  */

class mindlist {
   friend class mindnode;
public:
   /** Construct an empty list. */
   mindlist();
   /** Destruct the listheader and ALL! items. */
   virtual ~mindlist();
   /** Remove the item rem from the list. */
   virtual void remove(mindnode *rem);
   /** Number of elements in this list. */
   unsigned int count() const {return num;};
   /** Get the n_previous listelement. Internal iterator! You have to call last()
      before you call this method. Or be sure to be somewhere in the list. */
   mindnode* prev();
   /** Get n_next listelement. Internal iterator! You have to call first before
      you can use this function. */
   mindnode* next();
   /** Get last element. Internal iterator! Modifies the state of the list class.
   Use mindlist::end() mindnode::prev_node() to get none modifying head. */
   mindnode* last();
   /** Get first element. Internal iterator! Modifies the state of the list class.
      Use mindlist::begin() mindnode::next_node() to get none modifying head. */
   mindnode* first();
   /** Get the first element of the list without changing the list iterator. */
   inline mindnode * begin() const { return head; };
   /** Get the last element of the list without changing the list iterator. */
   inline mindnode * end() const { return tail; };
   /** The type used by the map-function. */
   typedef void (*mapfctn)(mindnode *, void *);
   /** Apply the function fctn to all elements of the list, starting with the first
       and suppling the additional information in add. This method doesn't use the
       internal iterator service -> It doesn't use first(), next() and last().*/
   void map(mapfctn, void *add);
   typedef void (*const_mapfctn)(mindnode const *, void *);
   /** Apply the function fctn to all elements of the list, starting with the first
       and suppling the additional information in add. This method doesn't use the
       internal iterator service -> It doesn't use first(), next() and last().*/
   void const_map(const_mapfctn, void *add) const;
   /** Remove all items from this list deleting them. */
   void clear();
   /** Duplicate the information of this list. */
   virtual mindlist * duplicateList();
   /** Return true, if the list contains no nodes. */
   inline bool isEmpty() const {return (num==0);};

   /** Inserting and appending. */

   /** Insert the node ins before the 'before' one. If before is null,
      then ins will be added to the beginning of the list.*/
   virtual void insertbefore(mindnode *ins, mindnode *before=0);
   /** Insert the list ins before the node 'before'. If before is null,
      then ins will be added to the beginning of the list.*/
   virtual void insertbefore(mindlist *ins, mindnode *before=0);
   /** Add the new item to the list, at first position. */
   inline void insert(mindnode* nw) {insertbefore(nw);};
   /** Add the new item to the list, at first position. */
   inline void insert(mindlist* ins) {insertbefore(ins);};
   /** Insert the node nw after the node after.  If the list is empty, nw will
       become it's only element. If after is NULL, nw will appended to the list.*/
   virtual void insertafter(mindnode* nw, mindnode* after=0);
   /** Insert the list ins after the node after.  If the list is empty, ins will
      become it's only element. If after is NULL, ins will appended to the list. */
   virtual void insertafter(mindlist * ins, mindnode * after=0);
   /** Append the new item to the list. */
   inline void append(mindnode *nw) {insertafter(nw);};
   /** Append the elements of tlist app to this one. The list app is empty afterwards. */
   inline void append(mindlist *app) {insertafter(app);};
   /** Create a new list by copying the nodes of the old one. */
   mindlist(const mindlist &old);
protected:
   /** The first and the last node in the list. */
   mindnode *head, *tail;
private:
   /** The amount of list elements. */
   unsigned int num;
   /** Contains the current element we are looking at. */
   mindnode *curr;
   /** Gets set if the current node was removed. The current-next-node becomes curr than. */
   bool remd_curr;
#ifdef DEBUG
private: // Methods
   /** Return true, if the node l is in the current list, else return false.
      The pointers are compared!!! */
   bool isIn(mindnode *l);
   void check() const;
#endif
};

#endif
