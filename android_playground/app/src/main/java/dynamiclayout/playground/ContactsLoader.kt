package dynamiclayout.playground

import android.content.Context
import android.provider.ContactsContract
import android.database.Cursor

data class Contact(
    val id: String,
    val name: String,
    val phone: String,
    val email: String
)

object ContactsLoader {
    fun load(context: Context, filter: String = ""): List<Contact> {
        val contacts = mutableListOf<Contact>()
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
            ContactsContract.CommonDataKinds.Phone._ID
        )
        val selection = if (filter.isNotBlank()) {
            "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?"
        } else null
        val selectionArgs = if (selection != null) arrayOf("%$filter%") else null
        val sortOrder = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"

        val cursor: Cursor? = context.contentResolver.query(
            uri, projection, selection, selectionArgs, sortOrder
        )

        cursor?.use {
            val idIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val nameIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIdx = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

            val seen = mutableSetOf<String>()
            while (it.moveToNext() && contacts.size < 100) {
                val contactId = it.getString(idIdx)
                if (contactId in seen) continue
                seen.add(contactId)

                contacts.add(Contact(
                    id = contactId,
                    name = it.getString(nameIdx) ?: "Unknown",
                    phone = it.getString(numberIdx) ?: "",
                    email = getEmail(context, contactId)
                ))
            }
        }
        return contacts
    }

    private fun getEmail(context: Context, contactId: String): String {
        val uri = ContactsContract.CommonDataKinds.Email.CONTENT_URI
        val cursor = context.contentResolver.query(
            uri, arrayOf(ContactsContract.CommonDataKinds.Email.ADDRESS),
            "${ContactsContract.CommonDataKinds.Email.CONTACT_ID} = ?",
            arrayOf(contactId), null
        )
        cursor?.use {
            if (it.moveToFirst()) return it.getString(0) ?: ""
        }
        return ""
    }
}
