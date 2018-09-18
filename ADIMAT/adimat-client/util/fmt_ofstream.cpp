/***************************************************************************
                          fmt_ofstream.cpp  -  description
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
 * $Log: fmt_ofstream.cpp,v $
 * Revision 1.12  2004/01/02 16:20:26  af116ve
 * Using the official cygwin and mingw preprocessor flags to add code for windows support. I.e., the insertion of a cariage return before a newline.
 *
 * Revision 1.11  2003/04/15 10:29:36  af116ve
 * Removed default argument in implementation to meet the standart restrictions.
 *
 * Revision 1.10  2002/09/24 20:16:11  af116ve
 * Tried to insert platform-specific line-ending character sequences. Did not succeed. Commented.
 *
 * Revision 1.9  2002/08/08 09:55:34  af116ve
 * If no filename is given, the output now is sent to the standart error.
 * Previously it was sent to stdout.
 *
 * Revision 1.8  2002/05/27 15:06:51  af116ve
 * Added constructors to enable output of the ast to the debugconsole.
 *
 * Revision 1.7  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#include "fmt_ofstream.h"
#include <errno.h>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <cassert>

/* The code of this constructor is copied from file fstream.h */
fmt_ofstream::fmt_ofstream(const char *name, int in_sp, std::ios::openmode om) :
      indent_level(0), indent_space(in_sp), toindent(false),
      han(new std::ofstream(name, std::ios::binary | om))
   {
     if (han == 0) {
       std::cerr << "adimat: error: failed to create output stream '"
                 << name << "': " << strerror(errno) << "\n";
     } else if (han->fail()) {
       std::cerr << "adimat: error: failed to open file '" << name << "': " << strerror(errno) << "\n";
     } else {
       rdbuf(han->rdbuf());
     }
   }

/** Open a formated output stream. Use the stringbuffer given. */
fmt_ofstream::fmt_ofstream(std::ostream &buf, int in_sp) :
  std::ostream(buf.rdbuf()), indent_level(0), indent_space(in_sp), toindent(false), han(0)
{ }

fmt_ofstream::~fmt_ofstream(){
   delete han;
}

void fmt_ofstream::indent() {
   int h= indent_level*indent_space;
   char * help;
   if (h) {
      help= (char *)malloc(sizeof(char)*h+1);
      for (int i=0; i<h; i++)
         help[i]=' ';
      if (han)
         han->write(help, h);
      else
         write(help, h);
      free(help);
   }
   toindent= false;
}

/** Output the character and check for newline. */
fmt_ofstream& fmt_ofstream::operator<<(char c) {
   if (toindent)
      indent();
   if (c=='\n') {
#if defined(__MINGW32__) || defined(__CYGWIN__)
      if (han)
         han->put('\r');
      else
         put('\r');
#endif
      toindent= true;
   }
   if (han)
      han->put(c);
   else
      put(c);
   return *this;
}


fmt_ofstream& fmt_ofstream::operator<<(const char *s) {
   char puffer[1000];
   int i, j=0;

#ifdef DEBUG
   if (! s) {
      std::cerr<< "<< char *-called with NULL-pointer."<< std::endl;
      return *this;
   }
#endif

   for(i= 0; s[i]!= '\0'; i++) {
#if defined(__MINGW32__) || defined(__CYGWIN__)
      if (s[i]== '\n')
         puffer[j++]= '\r';
#endif
      puffer[j]= s[i];
      j++;
      if (s[i]=='\n') {
         if (toindent)
            indent();
         if (han)
            han->write(puffer, j);
         else
            write(puffer, j);
         toindent= true;
         j=0;
      }
      /* Prevent puffer overflows. */
      if (j>990) {
         if (toindent)
            indent();
         if (han)
            han->write(puffer, j);
         else
            write(puffer, j);
         j=0;
      }
   }
   if (j)
      if (toindent)
         indent();
      if (han)
         han->write(puffer, j);
      else
         write(puffer, j);

   return *this;
}

/** Write a single number. */
fmt_ofstream& fmt_ofstream::operator<<(int i){
   char help[30];

   sprintf(help, "%d", i);
   this->operator<<(help);
   return *this;
}

/** Write a single number. */
fmt_ofstream& fmt_ofstream::operator<<(unsigned i){
   char help[30];

   sprintf(help, "%u", i);
   operator<<(help);
   return *this;
}
