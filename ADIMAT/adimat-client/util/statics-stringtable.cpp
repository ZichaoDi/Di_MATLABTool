#include "stringtable.h"

/** Initialize the instance of the Stringtable. No lazy instanziation is needed. */
const StringTable &StringTable::instance= StringTable();

const StringTable::id StringTable::zero={0};

/** Some static identifiers, which are used more than once. */
/* Newlines are treated the same in both Windows and Unix. The output-
 * stream cares about inserting the \r for Windows systems. */
const StringTable::id StringTable::nl_id= StringTable::get()->lookup("\n");
const StringTable::id StringTable::sem_nl_id= StringTable::get()->lookup(";\n");
const StringTable::id StringTable::sem_id= StringTable::get()->lookup("; ");
const StringTable::id StringTable::commata_id= StringTable::get()->lookup(", ");
const StringTable::id StringTable::zero_id= StringTable::get()->lookup("0");
const StringTable::id StringTable::one_id= StringTable::get()->lookup("1");
const StringTable::id StringTable::zeros_id= StringTable::get()->lookup("zeros");
const StringTable::id StringTable::log_id= StringTable::get()->lookup("log");
const StringTable::id StringTable::g_zeros_id= StringTable::get()->lookup("g_zeros");
const StringTable::id StringTable::g_dummy_id= StringTable::get()->lookup("g_dummy");
const StringTable::id StringTable::h_dummy_id= StringTable::get()->lookup("h_dummy");
const StringTable::id StringTable::nargin_id= StringTable::get()->lookup("nargin");
const StringTable::id StringTable::nargout_id= StringTable::get()->lookup("nargout");
const StringTable::id StringTable::equal_id= StringTable::get()->lookup("==");
const StringTable::id StringTable::logical_and_id= StringTable::get()->lookup("&");
const StringTable::id StringTable::clear_id= StringTable::get()->lookup("clear");
const StringTable::id StringTable::varargin_id= StringTable::get()->lookup("varargin");
const StringTable::id StringTable::varargout_id= StringTable::get()->lookup("varargout");
const StringTable::id StringTable::tilde_id= StringTable::get()->lookup("~");
const StringTable::id StringTable::curdir_id= StringTable::get()->lookup("./");

