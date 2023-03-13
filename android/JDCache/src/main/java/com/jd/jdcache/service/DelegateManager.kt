package com.jd.jdcache.service

import com.jd.jdcache.service.base.AbstractDelegate
import com.jd.jdcache.util.JDCacheLog.d
import com.jd.jdcache.util.JDCacheLog.e
import com.jd.jdcache.util.log
import java.lang.Exception
import java.lang.reflect.Modifier

internal object DelegateManager {
    private const val TAG = "DelegateManager"

    private val delegateMap: HashMap<String, Pair<Class<out AbstractDelegate>, AbstractDelegate?>>
        by lazy { HashMap<String, Pair<Class<out AbstractDelegate>, AbstractDelegate?>>() }

    @Suppress("UNCHECKED_CAST")
    fun <T : AbstractDelegate> getDelegate(delegateType: Class<out AbstractDelegate>): T? {
        val name = delegateType.name
        if (name == null || name.isEmpty()) {
            log { e(TAG, "Error in getting delegate instance. " +
                    "Delegate type (${delegateType}) is illegal.") }
            return null
        }
        val delegatePair = delegateMap[name]
        if (delegatePair == null) {
            log { e(TAG, "Error in getting delegate instance. " +
                    "Cannot find delegate for type $name, " +
                    "you must register it first.") }
            return null
        }
        var (delegateClass, delegate) = delegatePair
        if (delegate == null) {
            try {
                delegate = delegateClass.newInstance()
            } catch (e: Exception) {
                log {
                    e(TAG,
                        "Cannot create delegate's instance.",
                        e)
                }
            }
            val newDelegatePair = delegateClass to delegate
            delegateMap[name] = newDelegatePair
        }
        return delegate as T
    }

//    @Suppress("UNCHECKED_CAST")
    inline fun <reified T : AbstractDelegate> getDelegate(): T? {
        return getDelegate(T::class.java)
//        val name = T::class.qualifiedName
//        if (name == null || name.isEmpty()) {
//            log { e(TAG, "Error in getting delegate instance. " +
//                    "Delegate type (${T::class}) is illegal.") }
//            return null
//        }
//        val delegatePair = delegateMap[name]
//        if (delegatePair == null) {
//            log { e(TAG, "Error in getting delegate instance. " +
//                    "Cannot find delegate for type $name, " +
//                    "you must register it first.") }
//            return null
//        }
//        var (delegateClass, delegate) = delegatePair
//        if (delegate == null) {
//            try {
//                delegate = delegateClass.createInstance()
//            } catch (e: Exception) {
//                log {
//                    e(TAG,
//                        "Cannot create delegate's instance.",
//                        e)
//                }
//            }
//            val newDelegatePair = delegateClass to delegate
//            delegateMap[name] = newDelegatePair
//        }
//        return delegate as T
    }

    /**
     * 注册delegate的类，根据下述逻辑获取名字，相同名字的会被替换。
     * 名字逻辑：传入需注册服务的非抽象类，查找其父类，
     *      1.若直接父类为AbstractDelegate，则使用自身为名字；
     *      2.若直接父类为AbstractDelegate的子类，则继续往上找，最后使用AbstractDelegate的直接子类为名字。
     */
    @Suppress("UNCHECKED_CAST")
    fun addDelegateClass(delegateClass: Class<out AbstractDelegate>) {
        if (delegateClass == AbstractDelegate::class.java) {
            log { e(TAG, "Error in adding delegate class. " +
                    "Cannot add AbstractDelegate directly, you need to implement this class.") }
            return
        }
        val modifier = delegateClass.modifiers
        if (Modifier.isAbstract(modifier) || Modifier.isInterface(modifier)) {
            log { e(TAG, "Error in adding delegate class. Cannot add abstract class.") }
            return
        }
        var father: Class<out AbstractDelegate>? = delegateClass.superclass?.takeIf {
            AbstractDelegate::class.java.isAssignableFrom(it)
        } as Class<out AbstractDelegate>?

        var delegateType: Class<out AbstractDelegate> = delegateClass

        while (father != null && father != AbstractDelegate::class.java) {
            delegateType = father
            father = father.superclass?.takeIf {
                AbstractDelegate::class.java.isAssignableFrom(it)
            } as Class<out AbstractDelegate>?
        }

        val name = delegateType.name
        if (name == null || name.isEmpty()) {
            log { e(TAG, "Error in adding delegate class. " +
                    "Cannot find valid delegate type for your class: $delegateClass") }
            return
        }
        log { d(TAG, "Add delegate: $name -> ${delegateClass.name}") }
        delegateMap[name] = delegateClass to null
    }

}