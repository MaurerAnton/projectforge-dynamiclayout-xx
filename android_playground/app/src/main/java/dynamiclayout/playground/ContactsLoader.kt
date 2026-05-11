package dynamiclayout.playground

import android.content.Context
import android.database.Cursor
import android.provider.ContactsContract
import android.util.Log

data class Contact(
    val id: String,
    val name: String,
    val phone: String,
    val email: String
)

object ContactsLoader {
    private const val MAX_CONTACTS = 50

    fun load(context: Context, filter: String = ""): List<Contact> {
        val contacts = mutableListOf<Contact>()
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )
        val sortOrder = "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} ASC"

        var cursor: Cursor? = null
        try {
            cursor = context.contentResolver.query(uri, projection, null, null, sortOrder)
            if (cursor == null) {
                Log.w("DL", "Cursor is null from ContentResolver")
                return contacts
            }

            val idIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val nameIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIdx = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

            if (idIdx < 0 || nameIdx < 0 || numberIdx < 0) {
                Log.w("DL", "Column not found: id=$idIdx name=$nameIdx number=$numberIdx")
                return contacts
            }

            val seen = mutableSetOf<String>()
            while (cursor.moveToNext() && contacts.size < MAX_CONTACTS) {
                val contactId = cursor.getString(idIdx)
                if (contactId == null || contactId in seen) continue
                seen.add(contactId)

                contacts.add(Contact(
                    id = contactId,
                    name = cursor.getString(nameIdx) ?: "Unknown",
                    phone = cursor.getString(numberIdx) ?: "",
                    email = ""
                ))
            }
        } catch (e: Exception) {
            Log.e("DL", "Error loading contacts", e)
        } finally {
            cursor?.close()
        }

        return contacts
    }
}
