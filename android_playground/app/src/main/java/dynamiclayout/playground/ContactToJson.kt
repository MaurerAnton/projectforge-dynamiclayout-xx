package dynamiclayout.playground

/**
 * Converts a list of phone contacts into DynamicLayout JSON.
 * Generates: search input + N fieldsets (one per contact).
 * This is what the "server" would do — real data → layout JSON.
 */
object ContactToJson {

    fun generate(contacts: List<Contact>, filter: String = ""): Map<String, Any> {
        val layout = mutableListOf<Map<String, Any>>()

        // Search field
        layout.add(mapOf(
            "type" to "INPUT",
            "key" to "search",
            "id" to "search",
            "label" to "Search contacts",
            "dataType" to "STRING"
        ))

        // Contact count badge
        layout.add(mapOf(
            "type" to "INLINE_GROUP",
            "key" to "stats",
            "content" to listOf(
                mapOf("type" to "BADGE", "key" to "bdg_cnt", "title" to "${contacts.size} contacts", "color" to "primary"),
                mapOf("type" to "SPACER", "key" to "sp1", "width" to 8),
                mapOf("type" to "LABEL", "key" to "lbl_hint", "label" to "Showing first 100 contacts from your device")
            )
        ))

        layout.add(mapOf("type" to "SPACER", "key" to "sp2", "width" to 12))

        if (contacts.isEmpty()) {
            layout.add(mapOf(
                "type" to "ALERT",
                "key" to "alert_empty",
                "message" to "No contacts found" + if (filter.isNotBlank()) " matching \"$filter\"" else "",
                "color" to "warning"
            ))
        }

        // One FIELDSET per contact
        contacts.forEachIndexed { i, contact ->
            val fields = mutableListOf<Map<String, Any>>()

            fields.add(mapOf(
                "type" to "READONLY_FIELD",
                "key" to "ro_name_$i",
                "id" to "name_$i",
                "label" to "Name"
            ))

            if (contact.phone.isNotBlank()) {
                fields.add(mapOf(
                    "type" to "READONLY_FIELD",
                    "key" to "ro_phone_$i",
                    "id" to "phone_$i",
                    "label" to "Phone"
                ))
            }

            if (contact.email.isNotBlank()) {
                fields.add(mapOf(
                    "type" to "READONLY_FIELD",
                    "key" to "ro_email_$i",
                    "id" to "email_$i",
                    "label" to "Email"
                ))
            }

            layout.add(mapOf(
                "type" to "FIELDSET",
                "key" to "fs_$i",
                "title" to contact.name,
                "content" to fields
            ))
        }

        // Actions
        val actions = listOf(
            mapOf("type" to "BUTTON", "key" to "btn_refresh", "id" to "refresh", "title" to "Refresh", "color" to "primary"),
            mapOf("type" to "BUTTON", "key" to "btn_count", "id" to "count", "title" to "${contacts.size} total", "color" to "secondary")
        )

        // Build data map — prepopulate with contact values
        val data = mutableMapOf<String, Any>()
        contacts.forEachIndexed { i, contact ->
            data["name_$i"] = contact.name
            data["phone_$i"] = contact.phone
            data["email_$i"] = contact.email
        }
        data["search"] = filter

        return mapOf(
            "ui" to mapOf(
                "title" to "Contacts (${contacts.size})",
                "uid" to "android_contacts",
                "layout" to layout,
                "actions" to actions,
                "translations" to emptyMap<String, String>(),
                "userAccess" to mapOf("cancel" to true)
            )
        )
    }
}
