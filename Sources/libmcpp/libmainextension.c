/*-
 * Copyright (c) 1998, 2002-2008 Kiyoshi Matsui <kmatsui@t3.rim.or.jp>
 * All rights reserved.
 *
 * Some parts of this code are derived from the public domain software
 * DECUS cpp (1984,1985) written by Martin Minow.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include    "system.H"
#include    "internal.H"

#include <libgen.h>
#include <string.h>
#include <pthread.h>
#include <sys/resource.h>

#ifndef _WIN32
#include <unistd.h>
extern char *strdup(const char *__s1);
#endif

extern char* mcpp_dirname(char * path);

void mcpp_help() {
    char * argv[] = {
        "mcpp",
        "-h",
        NULL
    };
    mcpp_lib_main(2, argv);
}


void * mcpp_thread(void * mcpp_source_file) {
    char * srcFile = strdup(mcpp_source_file);
    char * srcFileCopy = strdup(mcpp_source_file);
            
    char * argv[] = {
        "mcpp",
        "-NPCk",
        "-I",
        (char *)mcpp_dirname(srcFileCopy),
        (char *)srcFile,
        NULL
    };
    
    char * result = mcpp_lib_main(5, argv);
    
    free(srcFile);
    free(srcFileCopy);
    
    return result;
}

const char * mcpp_preprocessFile(const char * srcFile) {
    
#ifndef _WIN32
    static pthread_mutex_t mcppLock = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&mcppLock);
    
    pthread_t thread_tid = 0;
    
    struct rlimit limit;
    pthread_attr_t attr;
    pthread_attr_t* attr_p = &attr;
    pthread_attr_init(attr_p);
    
    // Some systems, e.g., macOS, hav a different default default
    // stack size than the typical system's RLIMIT_STACK.
    // Let's use RLIMIT_STACK's current limit if it is sane.
    if(getrlimit(RLIMIT_STACK, &limit) == 0 &&
       limit.rlim_cur != RLIM_INFINITY &&
       limit.rlim_cur >= PTHREAD_STACK_MIN)
    {
        pthread_attr_setstacksize(&attr, (size_t)limit.rlim_cur);
    } else {
        attr_p = NULL;
    }
    
    pthread_create(&thread_tid, attr_p, mcpp_thread, (void *)srcFile);
    pthread_attr_destroy(&attr);
    
    void * result;
    pthread_join(thread_tid, &result);
    
    pthread_mutex_unlock(&mcppLock);
    
    return result;
#else
    return mcpp_thread((void *)srcFile);
#endif
}
