package com.jd.jdcache.util

fun <T : IUsefulCheck, R : MutableCollection<T>?> R.useful(needUseful: Boolean = true): R {
    return this?.let {
        val iterator = iterator()
        while (iterator.hasNext()){
            if ((needUseful && !iterator.next().useful())
                || (!needUseful && iterator.next().useful())) {
                iterator.remove()
            }
        }
        return it
    } ?: this
}

//fun <T : IUsefulCheck, R : MutableMap<Any, T>?> R.useful(needUseful: Boolean = true): R {
//    return this?.let {
//        val iterator = iterator()
//        while (iterator.hasNext()) {
//            if ((needUseful && !iterator.next().value.useful())
//                || (!needUseful && iterator.next().value.useful())) {
//                iterator.remove()
//            }
//        }
//        return it
//    } ?: this
//}

interface IUsefulCheck {
    fun useful(): Boolean
}