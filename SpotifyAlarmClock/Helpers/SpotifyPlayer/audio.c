/*
 * Copyright (c) 2010 Spotify Ltd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 *
 * Audio helper functions.
 *
 * This file is part of the libspotify examples suite.
 */

#include <sys/time.h>
#include "audio.h"

audio_fifo_data_t* audio_get(audio_fifo_t *af)
{
    //Determine max wait time
    struct timeval tv;
    struct timespec maxWait;
    gettimeofday(&tv, NULL);
    maxWait.tv_sec = tv.tv_sec + 10;
    maxWait.tv_nsec = 0;

    
    audio_fifo_data_t *afd;
    pthread_mutex_lock(&af->mutex);
  
    while (!(afd = TAILQ_FIRST(&af->q)))            
    {
        if(pthread_cond_timedwait(&af->cond, &af->mutex, &maxWait) != 0)        
        {
            pthread_mutex_unlock(&af->mutex);
            return NULL;
        }
    }
  
    TAILQ_REMOVE(&af->q, afd, link);
    af->qlen -= afd->nsamples;
  
    pthread_mutex_unlock(&af->mutex);
    return afd;
}

