/***************************************************************************
                          mindlist.cpp -  description
                             -------------------
    begin                : Fri May 4 2001
    copyright            : (C) 2001 by Andre Vehreschild
    email                : vehreschild@@sc.rwth-aachen.de
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
 * $Log: mindlist.cpp,v $
 * Revision 1.13  2004/05/12 14:33:52  af116ve
 * Cosmetics.
 * Constructors use initialisation instead of assignment now.
 * count is an inline method.
 *
 * Revision 1.12  2003/09/30 15:20:20  af116ve
 * Added debug symbol to prevent error in compile.
 *
 * Revision 1.11  2003/09/18 14:41:45  af116ve
 * Redesined interface of insert/append-method to more conveniert style.
 *
 * Revision 1.10  2003/07/25 12:23:57  af116ve
 * The type of the function passed to the map-method is now defined.
 * This enables easier casting of function objects.
 *
 * Revision 1.9  2003/07/03 13:52:22  af116ve
 * Removed bugs, that lead to memory leaks or crashes. (Valgrind!)
 *
 * Revision 1.8  2003/04/15 15:49:42  af116ve
 * It is save now to insert new items into the list during a map()-method call.
 *
 * Revision 1.7  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */

#include <set>
#include <cassert>
#include "loggingstream.h"
#include "mindlist.h"
#include "mindnode.h"

/** Construct an empty list. */
mindlist::mindlist(): head(0), tail(0), num(0), curr(0), remd_curr(false) {
#ifdef DEBUG
  logger(ls::TALKATIVE) << "Create mindlist " << (void*) this << "\n";
  check();
#endif
}

/** Create a new list by copying the nodes of the old one. */
mindlist::mindlist(const mindlist &old): head(0), tail(0), num(0),
   curr(0), remd_curr(false) {

#ifdef DEBUG
  logger(ls::TALKATIVE) << "Create copy of mindlist " << (void*) this << "\n";
#endif

   mindnode *act;

   for(act= old.head; act; act= act->n_next){
      append(act->duplicate());
   }

#ifdef DEBUG
   check();
#endif
}

/** Destruct the listheader and ALL! items. */
mindlist::~mindlist(){
#ifdef DEBUG
  logger(ls::TALKATIVE) << "Delete mindlist " << (void*) this << "\n";
#endif
   clear();
#ifdef DEBUG
   logger(ls::TALKATIVE) << "End delete mindlist " << (void*) this << "\n";
#endif
}

/** Get first element. */
mindnode* mindlist::first(){
   curr= head;
   remd_curr= false;
   return head;
}

/** Get last element. */
mindnode* mindlist::last(){
   curr= tail;
   remd_curr= false;
   return tail;
}

/** Get n_next listelement. Internal iterator! You have to call first before you can use this function. */
mindnode* mindlist::next(){
   if (! curr)
      return 0L;
   if (remd_curr)          // If the current node was removed the curr-filed is already the next node. */
      remd_curr= false;
   else
      curr= curr->n_next;
   return curr;
}

/** Get the n_previous listelement. Internal iterator! You have to call last() before you call
this method. Or be sure to be somewhere in the list. */
mindnode* mindlist::prev(){
   if (remd_curr)
      if (! curr)
         return last();
      else {
         remd_curr= false;
         return curr= curr->n_prev;
      }
   else
      if (! curr)
         return 0L;
      else
         return curr= curr->n_prev;
}

/** Remove the item rem form the list. */
void mindlist::remove(mindnode * rem){
#ifdef DEBUG
   mindnode * search;
   for(search=head; ((search) && (search!=rem)); search=search->n_next) ;
   if (search) {
#endif
      if (curr==rem) {
         next();
         remd_curr= true;
      }
      if (rem==head)
         head= rem->n_next;
      else
         rem->n_prev->n_next=rem->n_next;
      if (rem==tail)
         tail= rem->n_prev;
      else
         rem->n_next->n_prev= rem->n_prev;
      rem->mylist= 0;
      rem->n_next= 0;
      rem->n_prev= 0;
      --num;
#ifdef DEBUG
   } else
      logger(ls::ERROR)<< "mindlist::remove(): Listelement '"<< rem<< "' not in list '"<< this<< "'. Dubious!!!\n";
#endif
}

/** Apply the function fctn to all elements of the list, starting with the first
    and suppling the additional information in add. This method doesn't use the
    internal iterator service -> It doesn't use first(), next() and last().
    Extended to implement adding of elements savely. The next element is not
    fetched before fctn is applied to the current node. If new nodes are added
    after the current one, they will not be processed by this mapping. */
void mindlist::map(mapfctn fctn, void *add){
   mindnode *act= head, *next;

   if (! (head)) // Nothing in this list, return immediately.
      return ;

   next= act->n_next;
   while (act) {
      (*fctn)(act, add);
      act= next;
      if (next)
         next= next->n_next;
  }
}

/** Apply the function fctn to all elements of the list, starting with the first
    and suppling the additional information in add. This method doesn't use the
    internal iterator service -> It doesn't use first(), next() and last().
    Extended to implement adding of elements savely. The next element is not
    fetched before fctn is applied to the current node. If new nodes are added
    after the current one, they will not be processed by this mapping. */
void mindlist::const_map(const_mapfctn fctn, void *add) const {
   mindnode const *act= head, *next;

   if (! (head)) // Nothing in this list, return immediately.
      return ;

   next= act->n_next;
   while (act) {
      (*fctn)(act, add);
      act= next;
      if (next)
         next= next->n_next;
  }
}

/** Remove all items from this list deleting them. */
void mindlist::clear(){
   mindnode * c= head, * h;
#ifdef DEBUG
   unsigned int counter=0;
#endif

   while (c) {
#ifdef DEBUG
      ++counter;
#endif
      h= c->n_next;
      c->mylist= 0L;
#ifdef DEBUG
      logger(ls::TALKATIVE) << "mindlist::clear: delete item " << c << "\n";
#endif
      delete c;
      c= h;
   }
#ifdef DEBUG
   assert(counter==num);
#endif
   num=0;
   curr= head= tail= 0L;
   remd_curr= false;
}

/** Duplicate the information of this list. */
mindlist * mindlist::duplicateList(){
   return new mindlist(*this);
}


/******************************************************************************

         Inserting and appending.

******************************************************************************/

/** Insert the node ins before the before one. */
void mindlist::insertbefore(mindnode *ins, mindnode *before){
#ifdef DEBUG
   check();
#endif
   if((! (before))|| (before->n_prev== 0L)){
      if (head) {
         head->n_prev= ins;
         ins->n_next= head;
         head= ins;
      } else {
         head= ins;
         tail= ins;
      }
      ins->mylist= this;
      ++num;
#ifdef DEBUG
      check();
#endif
      return ;
   }

#ifdef DEBUG
   if (isIn(ins))
      logger(ls::WARNING)<< "Inserting node '"<< ins<< "' a second time.\n";
#endif
   ins->n_next= before;
   ins->n_prev= before->n_prev;
   before->n_prev->n_next= ins;
   before->n_prev= ins;
   ins->mylist= this;
   ++num;
#ifdef DEBUG
   check();
#endif
}

/** Insert the node ins before the before one. */
void mindlist::insertbefore(mindlist *ins, mindnode *before){
#ifdef DEBUG
   check();
#endif
   mindnode *act;

   for(act=ins->head; act; act= act->n_next) {
      act->mylist= this;
#ifdef DEBUG
      if (isIn(act))
         logger(ls::WARNING)<< "Inserting node '"<< act<< "' a second time.\n";
#endif
   }

   if((! (before))|| (before->n_prev== 0L)){ // No before pointer, add the nodes to the start of the list
      if(head) {
         if(ins->head){
            head->n_prev= ins->tail;
            ins->tail->n_next= head;
            head= ins->head;
            num+= ins->num;
         }
      } else {
         head= ins->head;
         tail= ins->tail;
         num= ins->num;
         curr= 0L;
         remd_curr= false;
      }
   } else {
      if(ins->head) {
         before->n_prev->n_next= ins->head;
         ins->head->n_prev= before->n_prev;
         before->n_prev= ins->tail;
         ins->tail->n_next=before;
         num+= ins->num;
      }
   }
   ins->tail= ins->curr= ins->head= 0L;
   ins->num =0;
   ins->remd_curr= false;

#ifdef DEBUG
   check();
#endif
}

/** Insert the node nw after the node after.  If the list is empty, nw will
 * become it's only element. If after is NULL, nw will appended to the list.*/
void mindlist::insertafter(mindnode* nw, mindnode* after){
#ifdef DEBUG
   check();
#endif
   if ((! (after)) || (after->n_next== 0L)) {
      if (tail) {
         tail->n_next= nw;
         nw->n_prev= tail;
         tail= nw;
      } else {
         head= nw;
         tail= nw;
      }
      nw->mylist= this;
      ++num;
#ifdef DEBUG
      check();
#endif
      return;
   }

#ifdef DEBUG
   if (isIn(nw))
      logger(ls::WARNING)<< "Inserting node '"<< nw<< "' a second time.\n";
#endif

   nw->n_next= after->n_next;
   after->n_next->n_prev= nw;
   after->n_next= nw;
   nw->n_prev= after;
   nw->mylist= this;
   ++num;
#ifdef DEBUG
   check();
#endif
}

/** Insert the list ins after the node after.  If the list is empty, ins will
  become it's only element. If after is NULL, ins will appended to the list. */
void mindlist::insertafter(mindlist * ins, mindnode * after){
#ifdef DEBUG
   check();
#endif
   mindnode *act;

      // Set all mylist pointers to this one
   for(act= ins->head; act; act= act->n_next) {
      act->mylist= this;
#ifdef DEBUG
      if (isIn(act))
         logger(ls::WARNING)<< "Inserting node '"<< act<< "' a second time.\n";
#endif
   }

   if ((! (after)) || (after->n_next== 0L)) {
      if(head){
         if(ins->head){
            tail->n_next= ins->head;
            ins->head->n_prev= tail;
            tail= ins->tail;
            num+= ins->num;
         }
      } else {
         head= ins->head;
         tail= ins->tail;
         num= ins->num;
      }
   } else {
      if(ins->head) {
         after->n_next->n_prev= ins->tail;
         ins->tail->n_next= after->n_next;
         after->n_next= ins->head;
         ins->head->n_prev=after;
         num+= ins->num;
      }
   }

   ins->head= ins->tail= ins->curr= 0;
   ins->num= 0;
   ins->remd_curr= false;

#ifdef DEBUG
   check();
#endif
}

#ifdef DEBUG
/** Check list for consistency: no double occurences, num correct. */
void mindlist::check() const {
  std::set<mindnode*> occs;
  mindnode * c= head;
  int count = 0;
  while (c) {
    std::set<mindnode*>::iterator it = occs.find(c);
    if (it != occs.end()) {
      std::cerr << "error: double occurence of node in list: " << c << "\n";
      assert(false);
    }
    occs.insert(c);
    c = c->n_next;
    ++count;
  }
  assert(count == num);
}

/** Return true, if the node l is in the current list, else return false.
   The pointers are compared!!! */
bool mindlist::isIn(mindnode *l) {
   for(mindnode *iter= head; (iter); iter=iter->n_next)
      if (iter==l)
         return true;
   return false;
}
#endif


