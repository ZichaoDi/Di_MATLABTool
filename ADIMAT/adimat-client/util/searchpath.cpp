/***************************************************************************
                          searchpath.cpp  -  description
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
 * $Log: searchpath.cpp,v $
 * Revision 1.10  2004/04/20 12:13:19  af116ve
 * Copy the buffer to truncate in multiAdd before processing to enable handling of const char* arrays.
 *
 * Revision 1.9  2004/01/02 17:11:37  af116ve
 * If an enviroment variable could not be ignored, the replaceEnv() function return 0. Which made the searchpath::add()-method crash, because it expected a valid string. Fixed.
 *
 * Revision 1.8  2004/01/02 16:40:05  af116ve
 * Now uses the constants of util.h for separators.
 *
 * Revision 1.7  2003/12/01 16:06:11  af116ve
 * Added preprocessor directives to compile correctly on Win32 systems. Replaced newline codes in the AST by the correct codes for Win32 Carrigage Return, NewLine.
 *
 * Revision 1.6  2003/07/03 13:52:22  af116ve
 * Removed bugs, that lead to memory leaks or crashes. (Valgrind!)
 *
 * Revision 1.5  2002/05/13 13:27:33  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#include <cstdio>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <string>

#include "searchpath.h"
#include "item_searchpath.h"
#include "client-util.h"
// #include "mach_env.h"
#include "loggingstream.h"

const char *BUILTINS_ID="@BUILTINS";

/** Create the SearchPath- class. It's empty now. */
SearchPath::SearchPath() :
   mindlist::mindlist(){
   builtinsused= false;
}

/** Free all path items. */
SearchPath::~SearchPath(){
}

/** Add one item to the search path. The contents of one is copied. */
void SearchPath::add(std::string const &one){
  item_SearchPath *it;
  // help stores the path with all env-vars replaced by their value
  std::string help;

  if (one.empty()) {
#ifdef DEBUG
    logger(ls::WARNING)<< "Empty string in SearchPath::add(). \n";
#endif
    return;
  }

  if(one.compare(BUILTINS_ID)==0) {   // check, if the current item is the special tag
    // @BUILTINS
    if(builtinsused){                // No double use of the special-tag allowed.
      logger(ls::ERROR)<< BUILTINS_ID<< " may occur only once in the searchpath. Only the first one is used.\n";
      return;
    }
    it = new item_SearchPath(BUILTINTAG);   // Built the special tag into the list.
    append(it);
    builtinsused= true;
    return;
  }

  help = replaceEnvs(one);
  if (not help.empty()) {
    /* Replacing environments variables failed. Skip this entry. */
    help = ensurePath(help);
     
    if (isDir(help)) {                     // A dir can be opened
      item_SearchPath *curr;
      for (curr= dynamic_cast<item_SearchPath *>(first()); ((curr)&& (! ((*curr)==help)));
           curr= dynamic_cast<item_SearchPath *>(next())) ;
      if (! curr) {  // The path is not inserted yet, append it.
        logger(ls::MINOR)<< '\''<< help<< "' is a valid directory, adding to search path.\n";
        it= new item_SearchPath(help);
        append(it);                      // It's a valid path so add it.
      }
    } else {
      // Something was wrong with the path, perhaps it was a file.
      logger(ls::WARNING)<< '\'' << help << "'"
        " is not a valid directory or inaccessible. Not added to search path!\n";
    }
  }
}

/** Add one or more entries to the searchpath by scanning the string for seperating ':'. */
bool SearchPath::multiAdd(char const *mult){
   char *buffer= strdup(mult);
   char *begin, *l;
#ifdef DEBUG
   logger(ls::TALKATIVE)<< "Path separators are '"<< PATH_SEPARATOR_UNIX << "' (unix)"
     " and '"<< PATH_SEPARATOR_WINDOWS << "' (windows)"
     " and directory separator is '"<< DIR_SEPARATOR<< "'.\n";
#endif

   begin=l=buffer;      // l is our look out variable.
   while ((*l)!='\0') {
      if ((*l)=='"') {  // Check for quoted path.
         l++;           // Overread the leading '"'
         while (((*l)!='"') && ((*l)!='\0'))
            l++;
         if ((*l)!='"') {
            logger(ls::ERROR)<< "Unterminated string constant in searchpath. Missing '\"'!\n";
            free(buffer);
            return false;
         }
      }

      if ((*l)==PATH_SEPARATOR_UNIX or (*l)==PATH_SEPARATOR_WINDOWS) {
         char const theSep = *l;
         *l='\0';       // Replace the ':' with a nullbyte to terminate the string.
         add(begin);    // add it to the list.
         *l = theSep;   // Reverse the modification just done.
         l++;           // go to the next char.
         begin=l;       // mult is the begining of each pathstring
      } else
         l++;
   }
   if (*begin!='\0') // If the last item isn't empty then add it.
      add(begin);
   free(buffer);
   return true;
}

/** Looks into the path and tries to find a file, that matches the name. */
std::string SearchPath::lookup(std::string const &name, std::string const &postfix) {
   item_SearchPath *isp= 0L;
   std::string mname, help;
   FILE *f= 0L;

   mname= name;
   mname+= postfix;

   do {
      if(isp)                             // Start condition, not initialzed so take the first one.
         isp= (item_SearchPath *)next();  // Let's look at the next candidate.
      else
         isp= (item_SearchPath *)first(); // Start with the first in the list

      if(isp) {
         help= isp->getPath()+ mname;     // concat the paths.

         logger(ls::MINOR) << "lookup(" << name << "): try to open " << help << "\n";
         f= fopen(help.c_str(), "r");     // Try to open the file.
      }
   } while ((! f) && (isp));              // Either the file could be opened or there were no more paths left.

   if (f) {                               // The file exists, this test doesn't tell us, if we are allowed to read it.
      fclose(f);                          // Be nice, close the file, to enable reopening later.
      logger(ls::MINOR) << "lookup(" << name << ") = " << isp->getPath() << "\n";
      return isp->getPath();
                                          // Return the path were we found the file.
   } else
     return "";                          // Return the empty string if we didn't find it.
}

