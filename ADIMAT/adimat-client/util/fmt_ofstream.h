/*** C++ *******************************************************************
                          fmt_ofstream.h  -  description
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
 * $Log: fmt_ofstream.h,v $
 * Revision 1.7  2002/08/08 09:55:34  af116ve
 * If no filename is given, the output now is sent to the standart error.
 * Previously it was sent to stdout.
 *
 * Revision 1.6  2002/05/27 15:06:51  af116ve
 * Added constructors to enable output of the ast to the debugconsole.
 *
 * Revision 1.5  2002/05/13 13:27:32  af116ve
 * Added Log directive to log changes in the source files within the source files, too.
 *
 */


#ifndef FMT_OFSTREAM_H
#define FMT_OFSTREAM_H

#include <ostream>
#include <fstream>
#include <iostream>
#include <ios>

/**fmt_ofstream has only one extension to the standart fstream. It looks for newline-characters in the outputstream and puts some indentation behind them.
  *@author Andre Vehreschild
  */

class fmt_ofstream : public std::ostream  {
private:
   /** The level of indentation. */
   int indent_level;
   /** How manny spaces per indenation step. */
   int indent_space;
   /** Put indent-many spaces into the stream. */
   void indent();
   /** Set if the next characters shall be indented. */
   bool toindent;
   /** The filehandle, if just a name was specified, and the file had to be opened. */
   std::ofstream *han;
public:
   /** Open a formated output stream. in_sp is the number statements are indented.*/
   fmt_ofstream(const char *name, int in_sp=3, std::ios::openmode om=std::ios::binary);
   /** Open a formated output stream. Use the stringbuffer given. */
   fmt_ofstream(std::ostream &outStream, int in_sp=3);
   /** Close the file, if not standart output */
   ~fmt_ofstream();
   /** Increase the indentation-level. */
   inline int operator++(int)
      {return ++indent_level;};
   /** Decrease the indenation-level. */
   inline int operator--(int)
      {indent_level--; if (indent_level<0) indent_level= 0; return indent_level;}
   /** Set the space of one indentation-level to space. */
   inline void setindent_space(int space) {indent_space= space;};
   /** Get the indentation space. Ever used? */
   inline int getindent_space() {return indent_space;};
   /** Filtering the output-data. */
   fmt_ofstream& operator<<(char);
   /** Filtering the output-data. */
   inline fmt_ofstream& operator<<(unsigned char c) { return (*this) << static_cast<char>(c); }
   /** Filtering the output-data. */
   inline fmt_ofstream& operator<<(signed char c) { return (*this) << static_cast<char>(c); }
   /** Filtering the output-data. */
   fmt_ofstream& operator<<(const char *s);
   /** Filtering the output-data. */
   inline fmt_ofstream& operator<<(const unsigned char *s)
         { return (*this) << reinterpret_cast<const char*>(s); };
   /** Filtering the output-data. */
   inline fmt_ofstream& operator<<(const signed char *s)
         { return (*this) << reinterpret_cast<const char*>(s); };
   /** Filtering the output-data. */
   inline fmt_ofstream& operator<<(fmt_ofstream& (*pf)(fmt_ofstream&)) {
      return pf(*this);
   }
   /** Write a single number. */
   fmt_ofstream& operator<<(int i);
   /** Write a single number. */
   fmt_ofstream& operator<<(unsigned i);
   /** Return status of stream. */
   inline std::ios_base::iostate rdstate() {return (han)? han->rdstate(): std::ostream::rdstate();};
   /** Set the status of the stream. */
   inline void setstate(std::ios_base::iostate state = goodbit) {
      if (han) han->setstate(state);
      else std::ostream::setstate(state);
   };
};

/** Add endl to the formated output stream. Remember, that this function is not in namespace std. */
inline fmt_ofstream& endl(fmt_ofstream& s) {
   s<< '\n';
   return s;
}
#endif
