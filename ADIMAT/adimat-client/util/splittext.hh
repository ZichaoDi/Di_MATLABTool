#ifndef adimat_splittext_hh
#define adimat_splittext_hh
// $Id: splittext.hh 916 2008-06-04 12:22:18Z willkomm $
// It's NO USE..  I've gone to ``CLUB MED''!!

#include <string>
#include <vector>

struct SplitText {
  std::vector<std::string> teile;
  
  SplitText(std::string const &text, std::string const &where, int maxSplits = 0) {
    size_t offset = 0;
    while(offset <= text.size()) {
      size_t const found = text.find(where, offset);
      if (found == std::string::npos or ((int)teile.size() >= maxSplits and maxSplits != 0)) {
	teile.push_back(text.substr(offset));
 	// std::cerr << "teil: " << text.substr(offset) << "\n";
	break;
      } else {
        std::string teil = text.substr(offset, found - offset);
        teile.push_back(teil);
        // std::cerr << "teil: " << teil << "\n";
        offset = found + where.size();
      }
    }
  }

  size_t size() const { return teile.size(); }

  std::string       &operator[](size_t const i)       { return teile[i]; }
  std::string const &operator[](size_t const i) const { return teile[i]; }

};

#endif
