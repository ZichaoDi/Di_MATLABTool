#ifndef adimat_libxml_util_hh
#define adimat_libxml_util_hh

#include <libxml/catalog.h>
#include <libxml/tree.h>
#include <libxml/parser.h>

#include <string>

xmlElement* getFirstChildElement(xmlNode * a_node);

xmlElement* getNextSiblingElement(xmlNode * a_node);

xmlNode* getFirstChildText(xmlNode * a_node);

xmlElement* getFirstChildElementByName(xmlNode * a_node, char const *name);

xmlAttribute* getAttributeByName(xmlElement * anElem, std::string const &name);

std::string getNodeContent(xmlNode * aNode);
inline std::string getNodeContent(xmlElement * anElem) { return getNodeContent((xmlNode *) anElem); }

std::string getAttributeContent(xmlElement * aNode, std::string const &name);

void prettyPrintTree(std::ostream &aus, xmlNode * a_node, std::string const &indent = "");

#endif
