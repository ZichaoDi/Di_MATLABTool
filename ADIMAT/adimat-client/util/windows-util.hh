#ifdef __WIN32
int initWSA(int const major = 2, int const minor = 2);
int shutdownWSA();
std::string winGetFolderPath();
std::string winGetFolderPathPersonal();
#endif
