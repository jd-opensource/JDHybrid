package com.jd.jdcache.util

import androidx.annotation.Keep
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job

@Keep
class CancellableJob(private val job: Job?) : ICancellable{

    override fun cancel(msg: String?) {
        if (job?.isCompleted == false) {
            val exMsg = if (msg.isNullOrEmpty()) {
                ""
            } else {
                " Msg: $msg"
            }
            job.cancel(CancellationException("Job canceled manually.$exMsg"))
        }
    }
}