#ifdef __WIN32
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <ws2tcpip.h>
#include <w32api.h>
#include <winsock2.h>
#include <shlobj.h>
#include <io.h>
#include <stdio.h>
#undef ERROR
#include "loggingstream.h"

int initWSA(int const major, int const minor) {
  WORD wVersionRequested;
  WSADATA wsaData;
  int err;
  
  /* Use the MAKEWORD(lowbyte, highbyte) macro declared in Windef.h */
  wVersionRequested = MAKEWORD(major, minor);
  
  err = WSAStartup(wVersionRequested, &wsaData);
  if (err != 0) {
    /* Tell the user that we could not find a usable */
    /* Winsock DLL.                                  */
    logger(ls::ERROR) << "WSAStartup failed with error: " << err << "\n";
    return 1;
  }
  
  /* Confirm that the WinSock DLL supports 2.2.*/
  /* Note that if the DLL supports versions greater    */
  /* than 2.2 in addition to 2.2, it will still return */
  /* 2.2 in wVersion since that is the version we      */
  /* requested.                                        */

  if (LOBYTE(wsaData.wVersion) != 2 || HIBYTE(wsaData.wVersion) != 2) {
    /* Tell the user that we could not find a usable */
        /* WinSock DLL.                                  */
    logger(ls::ERROR) << "Could not find a usable version of Winsock.dll\n";
    WSACleanup();
    return 1;
  }
  else
    logger(ls::MAJOR) << "The Winsock 2.2 dll was found okay\n";

  /* The Winsock DLL is acceptable. Proceed to use it. */
 
  return 0;
}  
  
int shutdownWSA() {
  /* then call WSACleanup when down using the Winsock dll */
  WSACleanup();
}

std::string winGetFolderPath() {
  std::string result;
  TCHAR szPath[MAX_PATH];
  HRESULT res = SHGetFolderPath(NULL, CSIDL_APPDATA, NULL, 0, szPath);
  if (SUCCEEDED(res)) {
    result = szPath;
    logger(ls::MAJOR) << "GetFolderPath(APPDATA): " << result << "\n";
  } else {
    logger(ls::ERROR) << "Failed to GetFolderPath(APPDATA)\n";
  }
  return result;
}

std::string winGetFolderPathPersonal() {
  std::string result;
  TCHAR szPath[MAX_PATH];
  HRESULT res = SHGetFolderPath(NULL, CSIDL_PERSONAL, NULL, 0, szPath);
  if (SUCCEEDED(res)) {
    result = szPath;
    logger(ls::MAJOR) << "GetFolderPath(PERSONAL): " << result << "\n";
  } else {
    logger(ls::ERROR) << "Failed to GetFolderPath(PERSONAL)\n";
  }
  return result;
}

#endif

