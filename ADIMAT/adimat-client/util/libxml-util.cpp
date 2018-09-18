#include "libxml-util.hh"

#include <string.h>
#include <iostream>

xmlElement* getFirstChildElement(xmlNode * a_node) {
  xmlNode *cur_node = NULL;
  xmlElement *res = 0;
  
  for (cur_node = a_node->children; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ELEMENT_NODE) {
      res = (xmlElement *)cur_node;
      break;
    }
  }
  return res;
}

xmlElement* getNextSiblingElement(xmlNode * a_node) {
  xmlElement *res = 0;
  for (xmlNode *cur_node = a_node->next; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ELEMENT_NODE) {
      res = (xmlElement *)cur_node;
      break;
    }
  }
  return res;
}

xmlNode* getFirstChildText(xmlNode * a_node) {
  xmlNode *cur_node = NULL;
  xmlNode *res = 0;
  
  for (cur_node = a_node->children; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_TEXT_NODE or cur_node->type == XML_CDATA_SECTION_NODE) {
      res = cur_node;
      break;
    }
  }
  return res;
}

xmlElement* getFirstChildElementByName(xmlNode * a_node, char const *name) {
  xmlNode *cur_node = NULL;
  xmlElement *res = 0;
  
  for (cur_node = a_node->children; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ELEMENT_NODE) {
      if (strcmp((char*)cur_node->name, name) == 0) {
        res = (xmlElement *)cur_node;
        break;
      }
    }
  }
  return res;
}

xmlAttribute* getAttributeByName(xmlElement * anElem, std::string const &name) {
  xmlNode *cur_node = NULL;
  xmlAttribute *res = 0;
  
  for (cur_node = (xmlNode *)anElem->attributes; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ATTRIBUTE_NODE) {
      if (strcmp((char*)cur_node->name, name.c_str()) == 0) {
        res = (xmlAttribute *)cur_node;
        break;
      }
    }
  }
  return res;
}

std::string getNodeContent(xmlNode * aNode) {
  xmlNode* textNode = getFirstChildText(aNode);
  std::string res;
  if (textNode) {
    res = (char const*) textNode->content;
  } else {
    std::cerr << "error: no text child node could be found\n";
  }
  return res;
}

std::string getAttributeContent(xmlElement * aNode, std::string const &name) {
  xmlAttribute* attr = getAttributeByName(aNode, name);
  std::string res;
  if (attr) {
    res = getNodeContent((xmlNode*) attr);
  } else {
    std::cerr << "error: no attribute named " << name << " could be found\n";
  }
  return res;
}

void prettyPrintTree(std::ostream &aus, xmlNode * a_node, std::string const &indent) {
  xmlNode *cur_node = NULL;
  for (cur_node = a_node->children; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ELEMENT_NODE) {
      aus << indent << cur_node->name;
      
      xmlElement *elem = (xmlElement *) cur_node;
      if (elem->attributes) {
        aus << "(";
        for (xmlAttribute *cur_attr = elem->attributes; cur_attr; 
             cur_attr = (xmlAttribute *)cur_attr->next) {
          if (elem->attributes != cur_attr) {
            aus << ",";
          }
          aus << cur_attr->name << "=" << getNodeContent((xmlNode*)cur_attr);
        }
        aus << ")";
      }
      aus << ": ";

      prettyPrintTree(aus, cur_node, indent + "  ");
    } else if (cur_node->type == XML_TEXT_NODE or cur_node->type == XML_CDATA_SECTION_NODE) {
      // Trim text((char const*) cur_node->content);
      // if (not text().empty()) {
        // aus << text() << "\n";
        aus << cur_node->content;
      // }
    }
  }
}
