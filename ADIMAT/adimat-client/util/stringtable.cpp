/***************************************************************************
                          stringtable.cpp  -  Store strings
                             -------------------
    begin                : Thu Apr 12 2001
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
 * $Log: stringtable.cpp,v $
 * Revision 1.13  2004/01/02 16:06:57  af116ve
 * Removed ifdef clause to specify a different nl_id on Win-plattform. The \r\n is not issued by the fmt_ofstream.
 *
 * Revision 1.12  2003/12/01 16:06:11  af116ve
 * Added preprocessor directives to compile correctly on Win32 systems. Replaced newline codes in the AST by the correct codes for Win32 Carrigage Return, NewLine.
 *
 * Revision 1.11  2003/10/20 14:37:47  af116ve
 * Added static const StringTable::identifiers for repeatedly occuring ids like "0", "1",...
 *
 * Revision 1.10  2003/07/25 12:24:32  af116ve
 * Better support for system-indepented builts.
 *
 * Revision 1.9  2003/07/03 13:52:22  af116ve
 * Removed bugs, that lead to memory leaks or crashes. (Valgrind!)
 *
 * Revision 1.8  2003/04/15 10:33:00  af116ve
 * Removed default argument in implementation to meet the standart restrictions.
 *
 * Revision 1.7  2002/06/14 17:49:40  af116ve
 * Implemented StringTable as singleton.
 *
 * Revision 1.6  2002/05/13 13:27:33  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <cassert>
#include <cctype>

#include "stringtable.h"
#include "loggingstream.h"



/** The structure to store unique names. */
struct unqnams {
   struct unqnams *next, *prev;
   StringTable::id basename;
   StringTable::id prefix;
   int num;
};

/** Initialize the stringtable by clearing some data, getting the hastable-
   memory and a default amount of index memory for the strings.
   Put the empty string a position 0.*/
StringTable::StringTable(): size(100), uniques(0){
   last.sym= 0;
   strs= (char**)malloc(size* sizeof(char *));
   hash= (id**)calloc(ADIMAT_MAXCHAR, sizeof(id *));
   assert(strs);  // Ensure we got the memmory.
   assert(hash);

   this->lookup("");
}

/** Destroy the stringtable. Free all strings and the index-
   structures. */
StringTable::~StringTable(){
   unqnam act;
   for(unsigned int i=0; i<last.sym; i++)
      free(strs[i]);
   free(strs);
   strs= NULL;
   for(int i=0; i<ADIMAT_MAXCHAR; i++)
      if (hash[i]) {
         free(hash[i]);
         hash[i]= NULL;
      }
   free(hash);
   if(uniques){
      act=uniques;
      while(act->next){
         act= act->next;
         free(act->prev);
      }
      free(act);
   }
}

/** Convenience version of lookup. */
StringTable::id StringTable::lookup(std::string const &s){
  return lookup(s.c_str());
}

/** Check if the string allready is stored by looking it up in
   the hashtable. If the string is allready in, then return its
   index, else copy the string and append it to the array of
   stringpointers and return the index. */
StringTable::id StringTable::lookup(const char *str){
   id *hashset;
   int hashval;
   int success=0;
   id one={1};

   if (! str)     // No string given, return the index on the empty string at 0
      return StringTable::zero;

   /* If we got a comment, we don't do hashing, but store it at the next free
      position in strs */
   if (str[0]!='%') {
      hashval=(int) toascii(str[0]);
      if (! hash[hashval]) {
         hashset=(id *)calloc(addhash+ 1, sizeof(id));
         assert(hashset);
         hashset[0]= one; // hashset[0] stores the amount of entries in this hashset
         hashset[1]= last;
         hash[hashval]= hashset;
      } else {
         int i;
         int setsize;

         hashset= hash[hashval];
         setsize=hashset[0].sym;
         for(i=1; i<=setsize; i++)
            if ((success= strcmp(str, strs[hashset[i].sym]))==0)
               break;
         if (success==0)
         // String found return its index.
            return hashset[i];

         setsize++;
         /* String wasn't found, check for enough room in the hashset and append
            a new pointer to the new string. */
         if (setsize% addhash==0) {
            hash[hashval]= (id *)realloc(hashset, (setsize+ addhash)* sizeof(id));
            assert(hash[hashval]);
            hashset= hash[hashval];
         }
         hashset[setsize]= last;
         hashset[0].sym++;
      }
   }

   /* The string has to be stored, check for room in the index, realloc more
      if not enough room is provided. */
   if (size<=last.sym+1) {
      size+= addstrs;
      strs= (char**) realloc(strs, size* sizeof(char *));
      assert(strs);
   }
   // Duplicate the string and store its pointer.
// #ifdef DEBUG
//    logger(ls::TALKATIVE)<< "StringTable::lookup: Store string "
//                         << str << " with ID " << last.sym << "\n";
// #endif
   strs[last.sym]= strdup(str);
   id prev= last;
   ++(last.sym);
   return prev;
}

/** Return the i-th string. Return NULL if i is out of range.*/
const char * StringTable::index(id i) const{
#ifdef DEBUG
   if (i.sym<last.sym)
#endif
      return strs[i.sym];
#ifdef DEBUG
   else {
     assert(0);
     return NULL;
   }
#endif
}

/** Return the id of a unique-name. If the parameter basename isn't
   supplied, than "unique" is used. The prefix is copied in front of
   the newly created name. */
StringTable::id StringTable::uniqueName(const char *basename, const char *prefix){
   return uniqueName(lookup(basename), prefix);
}

/** Like uniqueName, but accepts a valid stringtable index for basename. */
StringTable::id StringTable::uniqueName(StringTable::id basename, const char *prefix){
   char * fullname;
   int prelen= strlen(prefix);
   int bnlen= strlen(index(basename));
   id preid= lookup(prefix);
   id newid, oldlast;
   unqnam act, add;

      // Find the base node of this name.
   if(!uniques) { // No nodes found yet.
      uniques= (unqnam)malloc(sizeof(struct unqnams));
      uniques->next= 0L;
      uniques->prev= 0L;
      uniques->prefix= preid;
      uniques->basename= basename;
      uniques->num= 0;
      act= uniques;     // act's compound name is check a method for real uniqueness -> no occurence in the stringtable
   } else {       // Nodes found, because the nodes are sorted by the basenameid
                  // finding the current is done by linear search
      act= uniques;
      while((act->next)&& (act->basename.sym<basename.sym))
         act= act->next;

      if((act->basename.sym< basename.sym)&& (! (act->next))) { // A new node is needed, because all stored yet are to small
         add= (unqnam)malloc(sizeof(unqnams));
         add->next= 0L;
         add->prev= act;
         add->prefix= preid;
         add->basename= basename;
         add->num= 0;
            act->next= add;
         act= add;
      } else if(act->basename.sym>basename.sym) { // A new node is needed, because this basename wasn't needed as uniquename yet
                                       // Add before act
         add= (unqnam)malloc(sizeof(unqnams));
         add->next= act;
         add->prev= act->prev;
         if(act->prev)
            act->prev->next= add;
            else
            uniques= add;  // Add at first position
         act->prev= add;
         add->prefix= preid;
         add->basename= basename;
         add->num= 0;
         act= add;
      } else if((act->basename.sym== basename.sym)&&
            (act->prefix.sym!= preid.sym)){
                           // The basenames are identic, but now check if the prefixes are.
         while((act->next)&& (act->basename.sym== basename.sym)&&
               (act->prefix.sym< preid.sym))
            act= act->next;

         if((act->basename.sym== basename.sym)&& (act->prefix.sym> preid.sym)) // stepped to wide go back one step
            act= act->prev;
         if((act->basename.sym!= basename.sym)|| (act->prefix.sym!= preid.sym)) { // Insert a new entity before this one.
            add= (unqnam)malloc(sizeof(struct unqnams));
            add->next= act;
            add->prev= act->prev;
            if(act->prev)
               act->prev->next= add;
               else
               uniques= add;  // Add at first position
            act->prev= add;
            add->prefix= preid;
            add->basename= basename;
            add->num= 0;
            act= add;
          }
      }
   }

   // Now act has all information needed, construct the ident and check its uniqueness, until it is really unique.
   fullname=(char *)malloc(sizeof(char)* (bnlen+ prelen+ 7)); // Five chars should be enough for a unique number.
      // the other two byte are used by the underscore and the \0 at the end of the string.
   oldlast= last;
   do {
      sprintf(fullname,"%s%s_%05d", index(act->prefix), index(act->basename), act->num);
      newid= lookup(fullname);
      ++act->num;
   } while(oldlast.sym== last.sym);    // the item was appended at the list-> it didn't exist yet.
   free(fullname);            // Is in the strintable now
   return newid;
}

