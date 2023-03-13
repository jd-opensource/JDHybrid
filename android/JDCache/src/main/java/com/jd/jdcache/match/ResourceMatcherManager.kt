package com.jd.jdcache.match

import com.jd.jdcache.match.base.JDCacheResourceMatcher
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log
import java.lang.reflect.Modifier
import java.util.*

internal object ResourceMatcherManager {
    private const val TAG = "ResourceMatcherManager"

    private val defaultMatcherClassList : MutableList<Class<out JDCacheResourceMatcher>> by lazy {
        LinkedList<Class<out JDCacheResourceMatcher>>()
    }

    fun registerMatcher(matcherClass: Class<out JDCacheResourceMatcher>) {
        val modifier = matcherClass.modifiers
        if (Modifier.isAbstract(modifier) || Modifier.isInterface(modifier)) {
            log { e(TAG, "Error in adding register matcher class. " +
                    "Cannot register abstract class.") }
            return
        }
        if (matcherClass == JDCacheResourceMatcher::class) {
            log { e(TAG, "Error in adding register matcher class. " +
                            "Cannot add JDCacheResourceMatcher directly, you need to implement this class.")
            }
            return
        }
        defaultMatcherClassList.add(matcherClass)
    }

    fun unregisterMatcher(matcherClass: Class<out JDCacheResourceMatcher>) {
        defaultMatcherClassList.remove(matcherClass)
    }

    fun clearMatcher(){
        defaultMatcherClassList.clear()
    }

    fun createMatcher(clazz: Class<out JDCacheResourceMatcher>): JDCacheResourceMatcher? {
        return try {
            clazz.newInstance()
        } catch (e: Throwable) {
            log { e(TAG, "Error in creating matcher instance for ${clazz.simpleName}", e) }
            null
        }
    }

    fun createDefaultMatcherList(): LinkedList<JDCacheResourceMatcher> {
        val matcherList = LinkedList<JDCacheResourceMatcher>()
        defaultMatcherClassList.forEach { clazz ->
            try {
                matcherList.add(clazz.newInstance())
            } catch (e: Throwable) {
                log { e(TAG, "Error in creating matcher instance for ${clazz.simpleName}", e) }
            }
        }
        return matcherList
    }
}