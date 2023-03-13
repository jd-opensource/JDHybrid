package com.jd.jdcache.util


/**
 * List转为不支持key为null的Map。
 * getKey为获得map的key的方法。
 * 若getKey返回null，则那个item不存进map中。
 */
inline fun <reified K, reified V, reified M : MutableMap<K, V>>
        Collection<V>?.keyNonNullMap(getKey: (V) -> K?): M? {
    return if (!this.isNullOrEmpty()) {
        val map = M::class.java.newInstance()
        this.forEach { value ->
            getKey(value)?.let { key ->
                map[key] = value
            }
        }
        map
    } else {
        null
    }
}