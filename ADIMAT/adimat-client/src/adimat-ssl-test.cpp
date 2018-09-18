/*
 * Program: SSL-WOPR Terminal
 * Source : terminal.cpp
 * Purpose: Implementing an terminal for SSL connection to WOPR server.
 *
 * Copyright (c) 2009, 2010 Oliver Mueller.
 * All rights reserved.
 * http://www.cogito-ergo-sum.org
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the author be held liable for any damages arising from
 * the use of this software.
 *
 */

// We are on z/OS Unix System Services?
#ifdef __IBMCPP__
#if __IBMCPP__ >= 20000
#define _XOPEN_SOURCE_EXTENDED 1
#define _OPEN_MSGQ_EXT
#define WOPR_ZOS
#endif
#endif

#include <iostream>
#include <iomanip>

#include <sys/types.h>
#include <sys/wait.h>
#include <sys/select.h>

#include <unistd.h>
#include <fcntl.h>

#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/rand.h>

using namespace std;

#define BUFSIZE   8192

int main(int argc, const char *argv[])
{
    SSL_library_init();
    SSL_load_error_strings();
    ERR_load_BIO_strings();

    cout << "Terminal V1.00" << endl << endl;

    if(argc < 3 || argc > 4) {
        cout << "Usage: terminal host:port trust-certbundle [random-seed]" << endl;
        return 1;
    }

    const char *seed_file = NULL;
    if(argc == 4)
        seed_file = argv[3];

    SSL_CTX *ctx = SSL_CTX_new(SSLv3_client_method());

    if(!SSL_CTX_load_verify_locations(ctx, argv[2], NULL)) {
        cerr << "ERROR: Could not load trust store." << endl;
        return 1;
    }

    if(seed_file && !RAND_load_file(seed_file, 1048576)) {
        cerr << "ERROR: Could not read random seed." << endl;
        return 1;
    }

    SSL *ssl;
    BIO *bio = BIO_new_ssl_connect(ctx);
    if(bio == NULL) {
        cerr << "ERROR: Could not create connection object." << endl;
        return 1;
    }
    BIO_get_ssl(bio, &ssl);
    SSL_set_mode(ssl, SSL_MODE_AUTO_RETRY);

    BIO_set_conn_hostname(bio, argv[1]);

    if(BIO_do_connect(bio) <= 0) {
        cerr << "ERROR: Could not open connection." << endl;
        ERR_print_errors_fp(stderr);
        return 1;
    } else
        cout << "STATUS: Connection openend." << endl;

    if(SSL_get_verify_result(ssl) != X509_V_OK)
        cout << "STATUS: Certificate is invalid." << endl;
    else
        cout << "STATUS: Certificate is valid." << endl;

    // Initalization finished

    fd_set rfds, wfds;
    int cfd = BIO_get_fd(bio, NULL), maxfd = cfd + 1, r, wbuf_len = 0, wbuf_offset = 0 /*, n, resp_len */;
    char rbuf[BUFSIZE + 1], wbuf[BUFSIZE + 1], tmp[BUFSIZE + 1];
    // short currpmpt = 0;
    // bool nocmd;

    rbuf[BUFSIZE] = '\0';
    wbuf[BUFSIZE] = '\0';

    /*
     * To switch do non-blocking mode is not necessary,
     * according to BIO_s_connect(3) the BIO is already
     * in non-blocking mode after establishing of a
     * connection:
     * "BIO_set_nbio() sets the non blocking I/O flag to n.
     *  If n is zero then blocking I/O is set. If n is 1
     *  then non blocking I/O is set. Blocking I/O is
     *  the default. The call to BIO_set_nbio() should
     *  be made before the connection is established
     *  because non blocking I/O is set during the
     *  connect process."
     */

    wbuf[0] = '\0';
    wbuf_len = 0;

    for(;;) {
        FD_ZERO(&rfds);
        FD_ZERO(&wfds);
        FD_SET(cfd, &rfds);
        FD_SET(fileno(stdin), &rfds);
        if(wbuf_len)
            FD_SET(cfd, &wfds);

        if((r = select(maxfd, &rfds, &wfds, (fd_set*) 0, (struct timeval*) 0)) == 0)
            continue;

        if(FD_ISSET(cfd, &rfds)) {
            do {
                r = SSL_read(ssl, rbuf, BUFSIZE);
                switch(SSL_get_error(ssl, r)) {
                    case SSL_ERROR_NONE:
                        rbuf[r] = '\0';
#ifdef WOPR_ZOS
                        __atoe(rbuf);
#endif
                        cout << rbuf;
                        break;
                    case SSL_ERROR_ZERO_RETURN:
                        cout << "STATUS: Connection closed." << endl;
                        goto out_of_here;
                    case SSL_ERROR_SYSCALL:
                        if(ERR_get_error() == 0L) {
                            cout << "STATUS: Connection closed." << endl;
                            goto out_of_here;
                        }
                    default:
                        cerr << "ERROR: SSL read problem." << endl;
                        goto out_of_here;
                }
            } while(SSL_pending(ssl));
            flush(cout);
            goto continue_here;
out_of_here:
            break;
        }
continue_here:

        if(wbuf_len && FD_ISSET(cfd, &wfds)) {
            r = SSL_write(ssl, wbuf + wbuf_offset, wbuf_len);
            switch(SSL_get_error(ssl, r)) {
                case SSL_ERROR_NONE:
                    wbuf_len -= r;
                    if(wbuf_len <= 0) {
                        wbuf[0] = '\0';
                        wbuf_offset = 0;
                    } else
                        wbuf_offset += r;
                    break;
                case SSL_ERROR_WANT_WRITE:
                    break;
                default:
                    cerr << "ERROR: SSL write problem." << endl;
            }
        }

        if(FD_ISSET(fileno(stdin), &rfds)) {
            r = read(fileno(stdin), tmp, BUFSIZE);
            if(r == -1)
                cerr << "ERROR: " << strerror(errno) << "." << endl;
            else {
                tmp[r] = '\0';
#ifdef WOPR_ZOS
                __etoa(tmp);
#endif
                /*
                 * Note: This simple implementation is vulnerable to
                 *       buffer overflows! In real world implementation
                 *       this must be avoided.
                 */
                strcat(wbuf, tmp);
                wbuf_len += r;
            }
        }
    }

    BIO_free_all(bio);
    SSL_CTX_free(ctx);

    return 0;
}
