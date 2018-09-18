/***************************************************************************
              util.cpp  -  Collection of various utility functions
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
 * Revision: $Rev: 3517 $
 *           $Date: 2013-03-26 19:26:43 +0100 (Di, 26. Mär 2013) $
 *           $Author: willkomm $
 */

#include "client-util.h"

#include <cstdio>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <dirent.h>
#include <cassert>
#include <string>
#include <map>
#ifdef HAVE_WORDEXP
#include <wordexp.h>
#endif

//#include "mach_env.h"
#include "loggingstream.h"

using namespace std;

/** check if path exists and is a directory. */
bool isDir(std::string const &path) {
   DIR *hand;

   errno=0;                   // Delete old errors.
   hand= opendir(path.c_str());       // Try to open dir
   if ((hand) && (errno==0)) {   // A dir can be opened
      closedir(hand);
      return true;
   } else {
     logger(ls::MAJOR)<< "Cannot open directory '"<< path
                      << "': "<< strerror(errno)<< ".\n";
   }
   // Not a valid path, file or no permissions.
   return false;
}

/** check if file exists. */
bool fileExists(std::string const &filename) {
   FILE *hand;

   errno=0;                   // Delete old errors.
   hand= fopen(filename.c_str(), "r");      // Try to open dir
   if (hand) {                // A file can be opened
      fgetc(hand);            // and reading doesn't result in an error
      if (errno==0) {
         fclose(hand);
         return true;
      }                       // Not readable or problems. Report: It isn't a file.
      fclose(hand);
   }
   return false;
}

/** Checks, if in is a valid path, so if it terminates in a '/', if not the
   string is copied and a '/' is added and the new string is returned in out.
   out is null if the in-string was ok */
std::string ensurePath(std::string const &in) {
  std::string result(in);
  if (string(DIR_SEPARATORS_STR).find(result[result.size()-1]) == string::npos
      and not in.empty()) {
    result += DIR_SEPARATOR;
  }
  return result;
}

/** Ensures that the postfix is at the end of the filename.
   Behaviour like ensurePath. */
void ensurePostfix(char const *filename, const char *postfix, char **out) {
   int len=strlen(filename);
   int plen=strlen(postfix);
   int i, dif;
   bool failed= false;

   dif=len-plen;
   if(dif>0)
      for(i=0; ((i<plen)&& !failed); i++)
         failed=(filename[dif+ i]!= postfix[i]);
   else
      failed= true;

   if(failed) {
      (*out)= (char *)malloc(sizeof(char)* (len+ plen+ 1));
      strcpy((*out), filename);
      strcat((*out), postfix);
   } else
      (*out)= NULL;
}

/** Strip the last postfix from the filename by inserting a nullbyte
   at the dot position. If the first character of the string is the only
   dot then it won't be stripped. */
std::string stripPostfix(std::string const &in, std::string const &postfix) {
  int const len = in.size();
  int const plen= postfix.size();
  int const diff= len- plen;

  if(diff>0) {
    logger(ls::TALKATIVE)<< "suffix substring: `" << in.substr(diff, plen) << "'\n";
    if (in.substr(diff, len) == postfix) {
      return in.substr(0, diff);
    }
  }
  return in;
}

/** Return the smallest of the two arguments. */
int min(int a, int b){
   return ((a<b)? a: b);
}

/** Replace the environmentvariables in the string orig with their values.
   orig is copied anyway and the new pointer is returned by the function.*/
string replaceEnvs(string const &original) {

  std::string result;

#if defined HAVE_WORDEXP && defined USE_WORDEXP
  {
    wordexp_t wexpres;
    int const wc = wordexp(original.c_str(), &wexpres, WRDE_SHOWERR);
    if (wc != 0) {
      logger(ls::ERROR) << "wordexp expansion of string '" << 
        original << "' returned error " << wc << " " << strerror(wc) << "\n";
    }
    if (wexpres.we_wordc > 1) {
      logger(ls::WARNING) << "wordexp expansion of string '" << 
        original << "' returned more than one result (" << wexpres.we_wordc
                          << "), ignoring all but first\n";
      
    }
    
    result = wexpres.we_wordv[0];
    
    wordfree(&wexpres);
  }
#else
  
  size_t pDollar, pCBrace, pCur = 0;
  do {
    pDollar = original.find("${", pCur);
    if (pDollar == string::npos) {
      result += original.substr(pCur);
      break;
    } else {
      result += original.substr(pCur, pDollar - pCur);
      pCBrace = original.find("}", pDollar);
      if (pCBrace == string::npos) {
        logger(ls::ERROR) << "invalid variable string: cannot find closing brace in '" << original.substr(pDollar) << "'\n";
        result = original;
        break;
      }
      std::string envName = original.substr(pDollar + 2, pCBrace - pDollar - 2);
      ostream &mstr = logger(ls::MINOR);
      mstr << "looking up env: " << envName;
      char const *envVal = getenv(envName.c_str());
      if (envVal) {
        mstr << " = " << envVal << "\n";
        result += envVal;
      } else {
        mstr << "\n";
      }
      pCur = pCBrace + 1;
    }
  } while(1);
#endif

  logger(ls::MINOR) << "replaceEnvs(" << original << ") = " << result << "\n";
  return result;
}

 /** Check if the path supplied is absolute, by looking at the first char.
   On Unix-systems: The first char has to be a '/' to indicate an absolute path.
   On Win-system: The first char may be a '/', '\', of a char of [A-zA-Z] followed
      by a ':', to indicate an absolute path.
   Returns one if absolute, zero else.*/
bool isAbsolutePath(std::string const &path) {
   size_t const len = path.size();
   return (len>0 && ( path[0]=='/'
#if defined(__MINGW32__) || defined(__CYGWIN__)
           || path[0]=='\\' || (len>1 && isalpha(path[0]) && path[1]==':')
#endif
           ));
}

/** Strip the path of double DIR_SEPERATORS or /./ parts.
 * param  String with double slashes
 * returns Copy of string without double slashes and so on.*/
char * cleanupPath(const char *in) {
   if (! in)
      return 0;

   int i, len= strlen(in);
   char * out=(char *)malloc((len+ 1)* sizeof(char)); // Do not forget space for \0
   char * outp= out;
   const char *lastchar= in;
   bool seenslash= (in[0]== DIR_SEPARATOR);
   assert((out));
   *(outp++)= in[0];
   for(i=1; i< len; ++i, ++lastchar) {
      if ((in[i]==DIR_SEPARATOR) && (*lastchar==DIR_SEPARATOR))
         continue;
      else if ((in[i]=='.') && (*lastchar==DIR_SEPARATOR)) {
         if ((i+1<len) && (in[i+ 1]==DIR_SEPARATOR)) {
            // single dot found
            ++i; ++lastchar;
            continue;
         } else if ((i+2<len) && (in[i+1]=='.') && (in[i+2]== DIR_SEPARATOR) && seenslash) {
            // double dot found and allready one slash found
            if (outp-2>=out) {
               outp-= 2; //Step back over the last slash.
               while ((outp>out) && (*outp!= DIR_SEPARATOR))
                  --outp;
               ++outp;
            }
            i+=2; lastchar+= 2;
            continue;
         }
      }
      seenslash= seenslash || (in[i-1]== DIR_SEPARATOR);
      *(outp++)= in[i];
   }
   *outp= '\0';
   return out;
}

/** Strips the filename from fileandpath and stores a copy of it in
   stripped_filename. If a path is in fileandpath, then it is copied
   and stored in stripped_path. If no path is present, then a copy of
   the empty string "" is returned in stripped_path. The stripped_path
   is beautified (i.e. env-vars are inserted)
 */
void stripPathfromString(std::string const &fileandpath, 
                         std::string &stripped_path, std::string &stripped_filename) {
   size_t pSep = fileandpath.find_last_of(DIR_SEPARATORS_STR);
   if (pSep == string::npos) {
      // This fileandpath does not contain a path. At least none we recognize.
     stripped_filename = fileandpath;
     stripped_path = "";
     return;
   }
   stripped_filename = fileandpath.substr(pSep + 1);
   stripped_path = replaceEnvs(fileandpath.substr(0, pSep)); // w/o enviroment variables
}

