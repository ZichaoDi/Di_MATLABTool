/***************************************************************************
                          stringtable.h  -  Store all identifiers
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
 * $Log: stringtable.h,v $
 * Revision 1.9  2003/12/01 16:06:11  af116ve
 * Added preprocessor directives to compile correctly on Win32 systems. Replaced newline codes in the AST by the correct codes for Win32 Carrigage Return, NewLine.
 *
 * Revision 1.8  2003/10/20 14:37:47  af116ve
 * Added static const identifiers for repeatedly occuring ids like "0", "1",...
 *
 * Revision 1.7  2003/07/03 13:52:22  af116ve
 * Removed bugs, that lead to memory leaks or crashes. (Valgrind!)
 *
 * Revision 1.6  2002/06/14 17:49:40  af116ve
 * Implemented StringTable as singleton.
 *
 * Revision 1.5  2002/05/13 13:27:33  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#ifndef STRINGTABLE_H
#define STRINGTABLE_H

#include <ostream>
#include "fmt_ofstream.h"

#define ADIMAT_MAXCHAR 128

/** The stringtable stores all identifiers that are known during the program
  * run.
  *@author Andre Vehreschild
  */
class StringTable {
public:
   /** The type of an stringtable key. */
   typedef struct {unsigned int sym;} id;
  /* FIXME: use safer definition with constructors:
  struct id {
    id() : sym() {};
    id(unsigned int s) : sym(s) {};
    unsigned int sym;
    }; */
   /** Get a pointer to the one and only instance of the StringTable */
   inline static StringTable *get() {return const_cast<StringTable *>(&StringTable::instance);};
   /** Check if the string allready is stored by looking it up in
      the hashtable. If the string is allready in, then return its
      index, else copy the string and append it to the array of
      stringpointers and return the index. */
   id lookup(const char *str);
   id lookup(std::string const &);
   /** Return the i-th string. Return NULL if i is out of range.*/
   const char * index(id i) const;
   /** Return the id of a unique-name. If the parameter basename isn't
      supplied, than "unique" is used. The prefix is copied in front of
      the newly created name. */
   id uniqueName(const char *basename="unique", const char *prefix="tmp_");
   /** Like uniqueName, but accepts a valid stringtable index for basename. */
   id uniqueName(id basename, const char *prefix="tmp_");
   /** Destroy the stringtable. Free all strings and the index-
      structures. */
   ~StringTable();
   /** The empty id element. */
   static const id zero;
   /** Some static identifiers, which are used more than once. */
   static const id nl_id;
   static const id sem_nl_id;
   static const id sem_id;
   static const id commata_id;
   static const id zero_id;
   static const id one_id;
   static const id zeros_id;
   static const id log_id;
   static const id g_zeros_id;
   static const id g_dummy_id;
   static const id h_dummy_id;
   static const id nargin_id;
   static const id nargout_id;
   static const id equal_id;
   static const id logical_and_id;
   static const id clear_id;
   static const id varargin_id;
   static const id varargout_id;
   static const id tilde_id;
   static const id curdir_id;
protected:
   /** Initialze the stringtable by clearing some data, getting the hastable-
      memory and a default amount of index memory for the strings.
      Put the empty string a position 0.*/
   StringTable();
private: // Private attributes
   /* The one and only instance of the stringtable in this program. */
   static const StringTable &instance;
   /** Add this many hash-entries to an expanding hashset */
   static const int addhash= 10;
   /** Add this many stringpointer-entries to an expanding index-array.*/
   static const int addstrs= 100;
   /** The stringpointerarray. */
   char ** strs;
   /** The hashtable to quicken insert some what. */
   id **hash;
   /** First free entry of the stringpointerarray */
   id last;
   /** The size of the stringpointerarray*/
   unsigned int size;
   /** The list of uniquenames. */
   typedef struct unqnams *unqnam;
   unqnam uniques;
};

/** Shortcut for hashing a piece of text. */
inline StringTable::id toId(const std::string text) {
   return StringTable::get()->lookup(text);
}

/** Shortcut for retrieving a piece of text. */
inline std::string toString(const StringTable::id index) {
   return StringTable::get()->index(index);
}

/** Implement an output operator for the id-type. */
inline std::ostream & operator<<(std::ostream &out, const StringTable::id index){
   return operator<<(out, StringTable::get()->index(index));
}

/** Implement an output operator for the id-type. */
inline fmt_ofstream & operator<<(fmt_ofstream &out, const StringTable::id index){
   return out.operator<<(StringTable::get()->index(index));
}

/** Comparision operator for equality. */
inline bool operator==(StringTable::id l, StringTable::id r) {
   return (l.sym== r.sym);
}

/** Comparision operator for inequality. */
inline bool operator!=(StringTable::id l, StringTable::id r) {
   return (l.sym!= r.sym);
}

/** Comparision operator for less than. Sorting is done by id, not lexicographicaly. */
inline bool operator<(StringTable::id l, StringTable::id r) {
   return (l.sym< r.sym);
}

/** Comparision operator for not id-set. */
inline bool operator!(StringTable::id u) {
   return (! (u.sym));
}

#endif









